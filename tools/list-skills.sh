#!/usr/bin/env bash
set -eu

skill_root="${CODEX_SKILL_ROOT:-$HOME/.codex/skills}"
if [[ ! -d "$skill_root" ]]; then
  printf '找不到本機 Skill 目錄：%s\n' "$skill_root"
  printf '請確認宿主的安裝方式，或先完成 GETTING_STARTED.md 的安裝步驟。\n'
  exit 0
fi

find "$skill_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
