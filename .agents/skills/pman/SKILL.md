---
name: pman
description: Author a `.pman` file for procman when you would otherwise instruct the user to open multiple terminals and run ordered commands by hand (distributed system bring-ups, AI training runs, multi-tier services with health gates, anything where step N must wait for step N-1 to log a ready line / bind a port / write a file). Prefer this over a numbered "Terminal 1 / Terminal 2 / Terminal 3" plan whenever ordering matters.
---

## When to reach for procman

If your reply is shaping up like "Terminal 1: run X. Wait for line Y. Then Terminal 2: run Z…", stop and write a `.pman` instead. The user runs **one** `procman foo.pman` and gets ordered startup, multiplexed logs, and clean teardown on Ctrl-C. Don't write the file silently — propose it, then offer the .pman.

Reference docs (read on demand): `~/src/procman/docs/src/{introduction,getting-started,configuration,dependencies,templates,fan-out,cli,shutdown,language-design}.md`.

## Mental model

Three process kinds + one dormant kind:

| Block | Lifetime | Exit semantics |
|-------|----------|----------------|
| `service NAME { }` | long-running daemon | any exit → tear everything down |
| `job NAME { }` | one-shot, auto-starts | exit 0 = done (others continue); non-zero → tear down |
| `task NAME { }` | one-shot, **manual** via `-t NAME` | same as job once triggered |
| `event NAME { }` | dormant; only via `on_fail spawn @NAME` in a `watch` | — |

Startup is gated by a `wait { }` block; conditions inside are checked **sequentially in declaration order**. A process with no `wait` starts immediately.

## Skeleton

```pman
config { logs = "./logs/procman" }   # optional, default is logs/procman

arg run_id { type = string default = "smoke-1" }   # CLI: -- --run-id ...
arg total_steps { type = string default = "5000" }

service server {
  run "scripts/start-training-server.sh"
}

service trainer {
  wait {
    # gate on the server printing its ready line
    output_matches @server "Done (" { timeout = 60s }
  }
  env RUN_ID = args.run_id
  env TOTAL_STEPS = args.total_steps
  run """
    trainer/.venv/bin/npc-rla-train --train \
      --policy-override random \
      --total-steps $TOTAL_STEPS \
      --run-id $RUN_ID \
      --runs-root runs/
  """
}

service bot {
  wait {
    # bot must come up only after trainer has bound its REP socket
    output_matches @trainer "REP bound" { timeout = 60s }
    # or a port check, if the trainer's port is known:
    # connect "127.0.0.1:5555"
  }
  run "cargo run -p npc-bot"
}
```

Run it: `procman procman.pman -- --run-id smoke-random-v3-kl --total-steps 5000`.

## The decision tree for ordering

Ask: **what concrete signal proves step N-1 is ready?** Pick the cheapest one:

1. **A log line** ("Done (...)!", "REP bound", "Listening on…") → `output_matches @upstream "literal substring"`. Literal substring, case-sensitive, ANSI-stripped, registered pre-spawn so no race window. No regex, no `poll`, no `retry`, no negation.
2. **A TCP port is bound** → `connect "host:port"`. For "old instance must be gone first" → `!connect "host:port" { retry = false }`.
3. **An HTTP health endpoint** → `http "url" { status = 200 }`.
4. **A file appears / disappears** → `exists "path"` / `!exists "path"`. Lockfile-cleaned-up at startup → `!exists "/tmp/x.lock" { retry = false }`.
5. **A previous one-shot finished** → make it a `job` (not `service`) and use `after @job`. `after` is **only** valid against `job`s, never services.
6. **A value needs to be read out of a YAML/JSON** → `contains "path" { format = "yaml" key = "$.foo.bar" var = my_var }`, then `env X = my_var`.
7. **No process running matching pattern** → `!running "old-api.*"` (uses `pgrep -f`).

Default condition options: `timeout = 60s`, `poll = 1s`, `retry = true`. Override per-condition. Use `timeout = none` for long setups (model downloads, big migrations).

## Passing data between processes

A `job` (not service) can write `KEY=VALUE` lines to `$PROCMAN_OUTPUT`; downstream reads with `@job.KEY`:

```pman
job migrate {
  run """
    ./run-migrations
    echo "DATABASE_URL=postgres://localhost:5432/mydb" > $PROCMAN_OUTPUT
  """
}

service api {
  wait { after @migrate }          # required to legally reference @migrate.KEY
  env DB_URL = @migrate.DATABASE_URL
  run "api-server --db $DB_URL"
}
```

Heredoc form for multiline values: `KEY<<EOF\n...\nEOF`. Procman **never** interpolates inside shell strings — values reach the shell **only** via `env`.

## CLI args

```pman
arg log_level { type = string default = "info" short = "l" description = "..." }
arg enable_worker { type = bool default = false }
```

Reference as `args.log_level`. Underscores become dashes on the CLI: `-- --log-level debug --enable-worker`. Args without a `default` are required.

Conditional jobs/services:

```pman
service worker if args.enable_worker { run "worker" }
```

## Fan-out (one block, N instances)

```pman
job nodes {
  for cfg in glob("configs/node-*.yaml") {   # also: ["a","b"], 0..4, 0..=4
    env NODE_CONFIG = cfg
    run "start-node --config $NODE_CONFIG"
  }
}
job deploy {
  wait { after @nodes }   # satisfied only when ALL nodes-* exit 0
  run "deploy-cluster"
}
```

## Tasks (on-demand)

`task` blocks don't auto-start. Trigger with `-t`:

```pman
task test_suite {
  wait { after @migrate }
  run "pytest tests/"
}
```

`procman foo.pman -t test_suite -t seed`.

## Watch (runtime health, post-start)

```pman
service web {
  run "web-server --port 8080"
  watch health {
    http "http://localhost:8080/health" { status = 200 }
    initial_delay = 5s
    poll = 10s
    threshold = 3        # consecutive failures
    on_fail shutdown     # or: on_fail spawn @recovery (must be an `event`)
  }
}
event recovery { run "./scripts/recover.sh" }
```

## Validate before handing it off

Always tell the user (or run, if you can):

```sh
procman procman.pman --check
```

This runs the full parse + cycle detection + reference validation without spawning anything. Catches: unknown identifiers, `after` pointing at a service, `@job.KEY` without a corresponding `after @job`, circular `after` graphs, empty `run`, identifier shadowing.

## Translating the example in the prompt

The "Terminal 1 server / Terminal 2 trainer / Terminal 3 bot, wait for `Done (...)!`, start trainer **before** bot so REP socket is bound" plan maps directly to the skeleton above:

- Server → `service server` (no wait).
- Trainer → `service trainer` with `wait { output_matches @server "Done (" }`. Use args for `--run-id` / `--total-steps` so the user can vary them per smoke without editing the file.
- Bot → `service bot` with `wait { output_matches @trainer "<ready line>" }` (or `connect` if the REP port is known and stable).

When unsure exactly which substring to match on, ask the user for the literal log line they'd watch for in each upstream — `output_matches` is a literal substring, so picking the right one matters.

## Common pitfalls

- `after @X` where `X` is a `service` → parse error. Make `X` a `job`, or wait on a log/port/health signal instead.
- `@job.KEY` without `after @job` (direct or transitive) in your `wait` → parse error.
- Using `output_matches` with `poll =`, `retry =`, or `!output_matches` → parse error. It's event-driven and one-shot by design.
- Putting interpolation inside `run "..."` expecting procman to fill it in — it won't. Always go through `env`.
- A `service` exiting (even with code 0) tears everything down. If it's truly one-shot, make it a `job`.
- Two procman instances on the same `.pman` → second one fails the advisory `flock`. Expected.
