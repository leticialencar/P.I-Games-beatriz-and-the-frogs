#!/usr/bin/env bash
# Exporta o jogo para HTML5 em build/web (desktop browser / Render).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="$ROOT/build/godot_editor/Godot_v4.7-stable_linux.x86_64"
OUT="$ROOT/build/web/index.html"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Baixando Godot 4.7 standard (sem C#)..."
  mkdir -p "$ROOT/build/godot_editor"
  cd "$ROOT/build/godot_editor"
  curl -L --fail -o godot.zip \
    "https://github.com/godotengine/godot-builds/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip"
  unzip -o godot.zip
  chmod +x Godot_v4.7-stable_linux.x86_64
fi

if [[ ! -f "$ROOT/build/godot_templates/templates/web_nothreads_release.zip" ]]; then
  echo "Faltam templates Web em build/godot_templates/templates/"
  echo "Baixe Godot_v4.7-stable_export_templates.tpz e extraia web_nothreads_*.zip lá."
  exit 1
fi

mkdir -p "$ROOT/build/web"
cd "$ROOT/godot"
"$GODOT_BIN" --headless --path . --export-release "Web" "$OUT"
echo "OK → $ROOT/build/web"
ls -lh "$ROOT/build/web" | head
