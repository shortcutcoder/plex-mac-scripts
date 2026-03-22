# plex-mac-scripts

Version-controlled scripts for the Plex Mac Mini (`192.168.0.150`, user `plex`).

## Scripts

### AlwaysRunPlex.applescript
An AppleScript applet (Login Item) that:
1. Checks every 2 minutes whether all 10 NAS SMB shares are mounted
2. Mounts any missing shares via `mount_smbfs` (silent, no Finder windows)
3. Ensures Plex Media Server is running at all times
4. Handles graceful shutdown (quits Plex before the applet exits)

Deployed to: `/Applications/AlwaysRunPlex.app`

#### Bug History

**v3.0 (2026-03-22)** — Fixed: `isMounted()` used `quoted form of mountPath` in a shell
grep command. `quoted form` wraps the value in single-quotes (e.g. `'/Volumes/Movies'`),
but `mount(8)` output has no quotes: `... on /Volumes/Movies (smbfs, ...)`. The grep
never matched, so `mountShare()` was called every 2 minutes for **all 10 shares** even
when they were already mounted — causing constant noisy remount attempts.

Fix: Concatenate `mountPath` directly into the grep string without `quoted form`.

**v2.0 (2026-03-22)** — Rewrote original `MapDrives-LaunchPlex` (busy-wait loop + Finder
API) with an `idle`-based handler using `mount_smbfs` for silent mounting.

**v1.0 (original)** — `MapDrives-LaunchPlex.app`: busy-wait `repeat while` loop checking
drive count via Finder, launching Plex via Finder `launch` command.

## Deployment

To rebuild and deploy the `.app` from source:

```bash
# On the Mac Mini via SSH or terminal
osacompile -o /Applications/AlwaysRunPlex.app AlwaysRunPlex.applescript
```

Then ensure it's set as a Login Item in System Settings → General → Login Items.

## NAS Shares

| Share Name | Mount Point |
|---|---|
| Movies | /Volumes/Movies |
| Kids Movies | /Volumes/Kids Movies |
| TV | /Volumes/TV |
| TVCaroline | /Volumes/TVCaroline |
| Kids TV | /Volumes/Kids TV |
| AndrewPhotos | /Volumes/AndrewPhotos |
| CarolinePhotos | /Volumes/CarolinePhotos |
| Photos | /Volumes/Photos |
| HomeMovies | /Volumes/HomeMovies |
| Music | /Volumes/Music |

NAS host: `upsonnas`, SMB user: `plex`
