-- AlwaysRunPlex (silent mount edition)
-- Keep Plex running and ensure NAS SMB mounts exist without Finder UI.
-- 
-- CHANGELOG:
-- v3.0 (2026-03-22) - Fix: isMounted() used `quoted form` which added shell single-quotes
--                     around the mount path, causing grep to never match mount output.
--                     Result was constant remount spam every 2 min for all 10 shares.
--                     Fix: pass the mount path directly (not quoted form) in the grep cmd.
-- v2.0 (2026-03-22) - Rewrote with proper idle handler (no busy-wait loop), mount_smbfs
--                     instead of open smb://, graceful shutdown handler.
-- v1.0 (original)   - MapDrives-LaunchPlex: busy-wait loop with Finder-based mount check.

property nasMounts : {{share:"Movies", mount:"/Volumes/Movies"}, {share:"Kids Movies", mount:"/Volumes/Kids Movies"}, {share:"TV", mount:"/Volumes/TV"}, {share:"TVCaroline", mount:"/Volumes/TVCaroline"}, {share:"Kids TV", mount:"/Volumes/Kids TV"}, {share:"AndrewPhotos", mount:"/Volumes/AndrewPhotos"}, {share:"CarolinePhotos", mount:"/Volumes/CarolinePhotos"}, {share:"Photos", mount:"/Volumes/Photos"}, {share:"HomeMovies", mount:"/Volumes/HomeMovies"}, {share:"Music", mount:"/Volumes/Music"}}
property nasHost : "upsonnas"
property nasUser : "plex"

on run
	doit()
end run

on idle
	doit()
	return 120 -- check every 2 minutes
end idle

on quit
	-- Allow graceful shutdown: quit Plex before exiting so macOS can restart cleanly
	try
		do shell script "pkill -QUIT 'Plex Media Server' 2>/dev/null; sleep 3; pkill -KILL 'Plex Media Server' 2>/dev/null; true"
	end try
	continue quit
end quit

on doit()
	-- If the system is going down, do not fight it.
	try
		do shell script "uptime >/dev/null"
	on error
		return
	end try
	
	ensureMounts()
	
	-- Ensure Plex is running (background, no focus steal)
	try
		set plexRunning to (do shell script "pgrep -x 'Plex Media Server' >/dev/null 2>&1; echo $?")
	on error
		set plexRunning to "1"
	end try
	if plexRunning is not "0" then
		try
			do shell script "open -gj -a 'Plex Media Server'"
		end try
	end if
end doit

on ensureMounts()
	repeat with m in nasMounts
		set shareName to (share of m) as string
		set mountPath to (mount of m) as string
		try
			if isMounted(mountPath) is false then
				mountShare(shareName, mountPath)
			end if
		on error
			mountShare(shareName, mountPath)
		end try
	end repeat
end ensureMounts

on isMounted(mountPath)
	-- FIX v3.0: Do NOT use `quoted form of mountPath` here.
	-- `quoted form` adds shell single-quotes around the value, e.g. '/Volumes/Movies'
	-- but mount(8) output has no quotes: "... on /Volumes/Movies (smbfs, ...)"
	-- so the grep would never match, causing mountShare() to run every cycle for every share.
	-- Solution: concatenate mountPath directly into the grep string literal.
	set cmd to "mount | /usr/bin/grep -qF ' on " & mountPath & " ('; echo $?"
	try
		set rc to do shell script cmd
		return (rc is "0")
	on error
		return false
	end try
end isMounted

on mountShare(shareName, mountPath)
	-- Silent SMB mount: no Finder windows
	try
		do shell script "/bin/mkdir -p " & quoted form of mountPath
	end try
	try
		set smbSpec to "//" & nasUser & "@" & nasHost & "/" & shareName
		do shell script "/sbin/mount_smbfs " & quoted form of smbSpec & " " & quoted form of mountPath
	end try
end mountShare
