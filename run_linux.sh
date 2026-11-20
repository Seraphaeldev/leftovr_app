#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

if [ ! -f build/linux/x64/release/bundle/leftovr ]; then
  echo "Building leftovr for Linux..."
  flutter build linux
fi

echo "Launching leftovr..."
exec ./build/linux/x64/release/bundle/leftovr
