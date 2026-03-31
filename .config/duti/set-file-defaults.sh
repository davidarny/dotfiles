#!/usr/bin/env bash

set -euo pipefail

if ! command -v duti >/dev/null 2>&1; then
  echo "duti is not installed. Run: brew install duti" >&2
  exit 1
fi

if ! open -Ra "CotEditor"; then
  echo "CotEditor is not installed." >&2
  exit 1
fi

bundle_id="com.coteditor.CotEditor"
extensions=(
  bash
  c
  cc
  conf
  cpp
  css
  csv
  cxx
  dart
  diff
  go
  h
  hpp
  htm
  html
  ini
  java
  js
  json
  kt
  kts
  log
  lua
  m
  markdown
  md
  mjs
  mm
  mts
  php
  plist
  py
  rb
  rs
  scala
  sh
  sql
  svg
  swift
  tex
  toml
  ts
  tsv
  tsx
  txt
  xml
  yaml
  yml
  zsh
)

applied_extensions=()
skipped_extensions=()

for extension in "${extensions[@]}"; do
  printf 'Setting .%s -> CotEditor\n' "$extension"

  if duti -s "$bundle_id" ".$extension" all; then
    applied_extensions+=("$extension")
  else
    skipped_extensions+=("$extension")
  fi
done

if [ "${#applied_extensions[@]}" -eq 0 ]; then
  echo "No file associations were updated." >&2
  exit 1
fi
