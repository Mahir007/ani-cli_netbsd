# ani-cli NetBSD patch

Fixes an existing install of [ani-cli](https://github.com/pystardust/ani-cli) on NetBSD. Upstream fails there with:

```
deobfuscate_blob: arithmetic expression: variable contains non-numeric value: "_byte ^ 116"
No sources found for sub!
```

## Quick start

As root:

```sh
curl -fsSLO https://raw.githubusercontent.com/Mahir007/ani-cli_netbsd/netbsd-patch/netbsd-fix.sh
sh netbsd-fix.sh
```

If root can't find `ani-cli`, pass its path:

```sh
sh netbsd-fix.sh /usr/local/bin/ani-cli
```

Run it again after `ani-cli -U`, which restores the upstream code.

## What it changes

| Line in ani-cli | Change | Why |
| --- | --- | --- |
| `od -v -An -tu1` | `od -v -An -tx1` | NetBSD's `od` zero-pads decimal output, and `sh` reads a leading zero as octal. |
| `$((_byte ^ $1))` | `$((0x$_byte ^ $1))` | Reads the bytes as hex. |
| `sort -g -r -s` | `sort -n -r -s` | NetBSD's `sort` has no `-g`. |

## Troubleshooting

### Unrecognised ani-cli version

Upstream changed one of those lines. The script leaves the file as it was.

### Shows with separate audio tracks won't download

Upstream calls `ffmpeg` by name, and pkgsrc puts the version in the binary's name. As root, link both tools, using the version you have in `/usr/pkg/bin`:

```sh
ln -s /usr/pkg/bin/ffmpeg7 /usr/local/bin/ffmpeg
ln -s /usr/pkg/bin/ffprobe7 /usr/local/bin/ffprobe
```

Update the links if pkgsrc moves to a newer ffmpeg.
