---
name: profile-rust
description: Profile a Rust binary with samply on macOS, extract CPU hotspots, and measure memory usage. Use when you need to identify performance bottlenecks.
---

## Rust Profiling Workflow (macOS, samply)

Profile a Rust binary to identify CPU hotspots and memory usage. Use the binary or example and any
relevant flags from the current user request (e.g. `--example profile_encoding --size 32m`).

### Step 1: Build with debug symbols

Samply needs debug info for symbol resolution. Add a temporary `[profile.profiling]` to the
workspace `Cargo.toml` (if it does not exist already):

```toml
[profile.profiling]
inherits = "release"
debug = true
```

Then build with `cargo build --profile profiling` targeting the binary or example.

### Step 2: Generate dSYM bundle (critical on macOS)

On macOS, even with `debug = true`, symbols are stored in a separate dSYM bundle. **You must
run dsymutil** or samply will only show hex addresses:

```bash
dsymutil ./target/profiling/examples/<binary_name>
```

This creates a `.dSYM` directory next to the binary. Samply will find it automatically on the
next recording.

### Step 3: Record the profile

```bash
samply record --save-only -o /tmp/profile.json.gz ./target/profiling/examples/<binary> <args>
```

Key flags:
- `--save-only` — don't open the browser UI (needed for CLI/automation)
- `-o <path>` — output file location
- `--unstable-presymbolicate` — also emit a `.syms.json` sidecar with resolved symbols

**Important:** If you use `--unstable-presymbolicate`, the sidecar `.syms.json` file contains
the resolved symbols even when the main profile JSON only has hex addresses.

### Step 4: Extract hotspots from the profile

The samply profile JSON uses the Firefox Profiler format. The structure is:

```
profile.json.gz:
  threads[0]:
    stringArray[]         — string table
    funcTable.name[]      — indices into stringArray
    frameTable.func[]     — indices into funcTable
    stackTable.frame[]    — indices into frameTable
    stackTable.prefix[]   — parent stack ID (linked list)
    samples.stack[]       — stack ID per sample
```

**If symbols are hex addresses** (common on macOS without dsymutil), use the `.syms.json`
sidecar instead:

```
profile.json.syms.json:
  string_table[]                  — function names
  data[]:
    debug_name                    — library name (look for your binary name)
    symbol_table[]:
      rva                         — relative virtual address
      size                        — function size in bytes
      symbol                      — index into string_table
    known_addresses[]             — list of [address, symbol_index] pairs
```

To resolve addresses: binary search the `symbol_table` by `rva` to find which function
contains a given address.

#### Python extraction script pattern

```python
import json, gzip, bisect
from collections import defaultdict

# Load symbols from syms.json sidecar
with open('profile.json.syms.json') as f:
    syms = json.load(f)
sym_st = syms['string_table']

# Build address->symbol lookup for the main binary
main_syms = []
for entry in syms['data']:
    if '<binary_name>' in entry.get('debug_name', ''):
        for s in entry.get('symbol_table', []):
            main_syms.append((s['rva'], s['size'], sym_st[s['symbol']]))
main_syms.sort(key=lambda x: x[0])
rvas = [s[0] for s in main_syms]

def resolve(addr):
    idx = bisect.bisect_right(rvas, addr) - 1
    if 0 <= idx < len(main_syms):
        rva, size, name = main_syms[idx]
        if rva <= addr < rva + size:
            return name
    return f'0x{addr:x}'

# Load profile and aggregate samples
with gzip.open('profile.json.gz', 'rt') as f:
    data = json.load(f)
thread = data['threads'][0]
sa = thread['stringArray']
func_names = [sa[i] for i in thread['funcTable']['name']]
frame_func = thread['frameTable']['func']
stack_frame = thread['stackTable']['frame']
stack_prefix = thread['stackTable']['prefix']

# Resolve hex names
resolved = {}
for i, name in enumerate(func_names):
    resolved[i] = resolve(int(name, 16)) if name.startswith('0x') else name

# Count self-time and total-time per function
self_counts, total_counts = defaultdict(int), defaultdict(int)
for stack_id in thread['samples']['stack']:
    if stack_id is None: continue
    frames, sid = [], stack_id
    while sid is not None:
        frames.append(resolved[frame_func[stack_frame[sid]]])
        sid = stack_prefix[sid]
    self_counts[frames[0]] += 1
    for f in set(frames):
        total_counts[f] += 1

total = len(thread['samples']['stack'])
for func, count in sorted(self_counts.items(), key=lambda x: -x[1])[:15]:
    print(f'{100*count/total:5.1f}%  {func}')
```

### Step 5: Measure memory

On macOS, use `/usr/bin/time -l` (not the shell builtin) for peak RSS:

```bash
/usr/bin/time -l ./target/release/examples/<binary> <args>
```

Key fields in output:
- `maximum resident set size` — peak RSS in bytes
- `peak memory footprint` — similar, sometimes more accurate on newer macOS

### Step 6: Clean up

Remove the `[profile.profiling]` from `Cargo.toml` if it was only needed temporarily, or
commit it if the project will benefit from it long-term.

### Common pitfalls

1. **No symbols in profile** — Almost always means dsymutil wasn't run. The dSYM bundle must
   exist next to the binary *before* samply records.
2. **samply opens browser** — Use `--save-only` to suppress.
3. **Profile too short** — Use `--iterations` or `--duration` to extend the recording. Aim for
   >1000 samples for statistical significance.
4. **`stringArray` vs `stringTable`** — Older samply versions use `stringTable`, newer use
   `stringArray`. Check `thread.keys()`.
5. **funcTable has no `schema` key** — Newer format uses named arrays (`funcTable.name[]`)
   instead of `funcTable.schema` + `funcTable.data[][]`.
