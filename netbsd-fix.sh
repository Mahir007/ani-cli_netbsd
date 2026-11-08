#!/bin/sh
set -eu

die() {
    printf "%s\n" "$1" >&2
    exit 1
}

target="${1:-$(command -v ani-cli || true)}"
[ -f "$target" ] || die "ani-cli not found. Usage: $0 [path/to/ani-cli]"

tmp="$target.tmp"
trap 'rm -f "$tmp"' EXIT
cp -p "$target" "$tmp"

sed -e 's/od -v -An -tu1)/od -v -An -tx1)/' \
    -e 's/_char=\$((_byte ^ \$1))/_char=$((0x$_byte ^ $1))/' \
    -e 's/sort -g -r -s/sort -n -r -s/' "$target" >"$tmp"

for fixed in 'od -v -An -tx1)' '_char=$((0x$_byte ^ $1))' 'sort -n -r -s'; do
    grep -qF -- "$fixed" "$tmp" || die "Unrecognised ani-cli version, $target is unchanged"
done
sh -n "$tmp"

mv "$tmp" "$target"
printf "Patched %s\n" "$target"
