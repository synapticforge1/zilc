#!/bin/sh
# Install the zilc P1 toolchains into the WSL home. Idempotent: skips what exists.
set -e

WORK="$HOME/zilc-work"
DL="$WORK/dl"
TOOLS="$WORK/tools"
mkdir -p "$DL" "$TOOLS"

ZIG_URL="https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz"
ZIG_SHA="02aa270f183da276e5b5920b1dac44a63f1a49e55050ebde3aecc9eb82f93239"
# Fil-C: the release zilc builds on (tools/lib/tool.ts FILC_VERSION). Upstream publishes no
# checksum; this is the SHA-256 of the file as downloaded on 2026-10-05, recorded so a later
# download can be checked against it. FILC_VERSION=0.685 still installs the release the phase
# experiments (tools/p1–p3) record (its SHA was only printed then, so it is not checked).
FILC_VERSION=${FILC_VERSION:-0.686}
FILC_URL="https://github.com/pizlonator/fil-c/releases/download/v$FILC_VERSION/filc-$FILC_VERSION-linux-x86_64.tar.xz"
[ "$FILC_VERSION" = 0.686 ] && FILC_SHA="60bfbe8ee63d7e462394aa8d5e44fee675de892bcf800d9cc80d86378cad6b07" || FILC_SHA=""

echo "== 1/4 Zig 0.15.2"
if [ -x "$TOOLS/zig-0.15.2/zig" ]; then
  echo "already installed"
else
  [ -f "$DL/zig.tar.xz" ] || curl -fsSL "$ZIG_URL" -o "$DL/zig.tar.xz"
  got=$(sha256sum "$DL/zig.tar.xz" | cut -d' ' -f1)
  if [ "$got" != "$ZIG_SHA" ]; then
    echo "SHA MISMATCH: got $got want $ZIG_SHA" >&2
    exit 1
  fi
  echo "sha256 OK"
  tar -xJf "$DL/zig.tar.xz" -C "$TOOLS"
  mv "$TOOLS/zig-x86_64-linux-0.15.2" "$TOOLS/zig-0.15.2"
fi
"$TOOLS/zig-0.15.2/zig" version
"$TOOLS/zig-0.15.2/zig" cc --version | head -1

echo "== 2/4 Fil-C $FILC_VERSION"
FILC="$TOOLS/filc-$FILC_VERSION-linux-x86_64"
if [ -d "$FILC" ]; then
  echo "already unpacked"
else
  T="$DL/filc-$FILC_VERSION.tar.xz"
  [ -f "$T" ] || curl -fsSL "$FILC_URL" -o "$T"
  got=$(sha256sum "$T" | cut -d' ' -f1)
  echo "$got  $T" | tee "$DL/filc-$FILC_VERSION.sha256"
  if [ -n "$FILC_SHA" ] && [ "$got" != "$FILC_SHA" ]; then
    echo "SHA MISMATCH: got $got want $FILC_SHA" >&2
    exit 1
  fi
  tar -xJf "$T" -C "$TOOLS"
fi
ls "$FILC" | head -20

echo "== 2b/4 patchelf (needed by Fil-C setup.sh; installed WITHOUT root)"
PBIN="$TOOLS/bin"
mkdir -p "$PBIN"
if [ -x "$PBIN/patchelf" ]; then
  echo "already installed"
else
  curl -fsSL "https://github.com/NixOS/patchelf/releases/download/0.19.1/patchelf-0.19.1-x86_64.tar.gz" -o "$DL/patchelf.tar.gz"
  sha256sum "$DL/patchelf.tar.gz" | tee "$DL/patchelf.sha256"
  mkdir -p "$DL/patchelf"
  tar -xzf "$DL/patchelf.tar.gz" -C "$DL/patchelf"
  cp "$DL/patchelf/bin/patchelf" "$PBIN/patchelf"
  chmod +x "$PBIN/patchelf"
fi
PATH="$PBIN:$PATH"
export PATH
patchelf --version

echo "== 3/4 Fil-C setup.sh"
if [ -f "$FILC/.setup-done" ]; then
  echo "already run"
else
  cd "$FILC"
  ./setup.sh
  touch .setup-done
fi

echo "== 4/4 Deno"
if [ -x "$HOME/.deno/bin/deno" ]; then
  echo "already installed"
else
  curl -fsSL https://deno.land/install.sh | DENO_INSTALL="$HOME/.deno" sh -s -- -y >/dev/null
fi
"$HOME/.deno/bin/deno" --version | head -1

echo "== done"
