#!/bin/sh
set -eu

fail() {
    printf "FAIL: %s\n" "$1" >&2
    exit 1
}

[ "$#" -eq 1 ] || fail "usage: $0 path/to/upstream/ani-cli"

script="$PWD/netbsd-fix.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
target="$work/ani-cli"

cp "$1" "$target"
chmod 750 "$target"
sh "$script" "$target" >/dev/null || fail "script failed on upstream"

blob="FFYSGRYPX08KERBdBQtAWxlFAUgWGU0ESkBFRFdWTUkBRBEBB0deDxVQCbfIS5avx08f"
expected='{"src":"https://x.test/a.m3u8","title":"café ア"}'
actual="$({
    sed -n '/^b64_decode() {/,/^}/p; /^deobfuscate_blob() (/,/^)/p' "$target"
    printf 'deobfuscate_blob %s\n' "$blob"
} | sh)" || fail "deobfuscate_blob exited with an error"
[ "$actual" = "$expected" ] || fail "deobfuscate_blob printed: $actual"

sort_flags="$(sed -nE 's/.*\| sort (-[a-z -]+)\)"$/\1/p' "$target")"
[ -n "$sort_flags" ] || fail "can't find the quality sort"
#shellcheck disable=SC2086
sorted="$(printf '360 >c\n1080 >a\n720 >b\n' | sort $sort_flags | cut -d ' ' -f 1 | tr '\n' ' ')"
[ "$sorted" = "1080 720 360 " ] || fail "sort $sort_flags printed: $sorted"

[ "$(ls -l "$target" | cut -c1-10)" = "-rwxr-x---" ] || fail "mode not kept"
[ "$(ls -A "$work")" = "ani-cli" ] || fail "left extra files behind"

cp "$target" "$work/before"
sh "$script" "$target" >/dev/null || fail "second run failed"
cmp -s "$target" "$work/before" || fail "second run changed the file"
rm "$work/before"

refused() {
    cp "$work/case" "$work/case.orig"
    if sh "$script" "$work/case" >/dev/null 2>&1; then
        fail "$1: accepted"
    fi
    cmp -s "$work/case" "$work/case.orig" || fail "$1: file changed"
    [ ! -e "$work/case.tmp" ] || fail "$1: left temp file"
    rm "$work/case" "$work/case.orig"
}

printf 'echo hello\n' >"$work/case"
refused "unrelated file"

printf 'x | od -v -An -tu1)\n' >"$work/case"
refused "partial match"

{
    printf '%s\n' 'x | od -v -An -tu1)' 'sort -g -r -s'
    printf '%s\n' '_char=$((_byte ^ $1))'
    printf 'if true\n'
} >"$work/case"
refused "syntax error"

if sh "$script" "$work/missing" >/dev/null 2>&1; then
    fail "missing file: accepted"
fi

printf "ok\n"
