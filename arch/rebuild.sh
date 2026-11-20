#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

echo "Building Linux bundle..."
flutter build linux

echo "Staging package sources..."
rm -rf arch/stage arch/src
mkdir -p arch/stage/bundle
cp -a build/linux/x64/release/bundle/. arch/stage/bundle/
cp linux/leftovr.desktop linux/assets/leftovr.png arch/stage/
tar -czf arch/leftovr-bundle-1.0.0.tar.gz -C arch/stage .

echo "Building Arch package..."
cd arch
makepkg -f

echo
echo "Install with:"
echo "  sudo pacman -U $PWD/leftovr-1.0.0-1-x86_64.pkg.tar.zst"
