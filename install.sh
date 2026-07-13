#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

install_link() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'error: link source does not exist: %s\n' "$source" >&2
    return 1
  fi

  if [[ -L "$target" ]]; then
    if [[ "$target" -ef "$source" ]]; then
      printf 'already linked: %s -> %s\n' "$target" "$source"
      return
    fi

    printf 'relinking: %s -> %s\n' "$target" "$source"
    ln -sfn "$source" "$target"
    return
  fi

  if [[ -e "$target" ]]; then
    printf 'error: refusing to replace non-symlink: %s\n' "$target" >&2
    return 1
  fi

  printf 'linking: %s -> %s\n' "$target" "$source"
  ln -s "$source" "$target"
}

install_link "$repo_dir/.agents" "$HOME/.agents"
install_link "$repo_dir/.claude" "$HOME/.claude"
