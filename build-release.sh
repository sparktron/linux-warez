#!/usr/bin/env bash
# Build the committed ./installer as a static musl binary.
#
# Ubuntu 22.04 is glibc 2.35 and Ubuntu 24.04 is glibc 2.39. A binary
# linked against the glibc Rust target requires GLIBC_2.39 (see
# .cargo/config.toml) and will not start on 22.04. This script builds
# x86_64-unknown-linux-musl, refuses a glibc-linked result, and copies
# the binary to ./installer.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="x86_64-unknown-linux-musl"
bin="${root}/installer-tui/target/${target}/release/installer-tui"

cd "${root}/installer-tui"
cargo build --release --target "${target}"

desc="$(file -b "${bin}")"
if ! grep -Eq 'statically linked|static-pie' <<<"${desc}"; then
  echo "error: ${bin} is not a static binary: ${desc}" >&2
  exit 1
fi

ldd_out="$(ldd "${bin}" 2>&1 || true)"
if grep -q 'libc\.so' <<<"${ldd_out}"; then
  echo "error: ${bin} is linked against glibc" >&2
  echo "${ldd_out}" >&2
  exit 1
fi

/usr/bin/cp "${bin}" "${root}/installer"
chmod +x "${root}/installer"

"${root}/installer" --dump-json >/dev/null
echo "OK ${root}/installer (${desc})"
