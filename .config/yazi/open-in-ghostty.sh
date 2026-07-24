#!/bin/sh

path=${1:-$PWD}
[ -d "$path" ] || path=$(dirname "$path")

osascript - "$path" <<'APPLESCRIPT'
on run argv
	set targetDir to item 1 of argv

	tell application "Ghostty"
		activate
		set cfg to new surface configuration
		set initial working directory of cfg to targetDir

		set currentTerm to focused terminal of selected tab of front window
		set newTerm to split currentTerm direction down with configuration cfg
		focus newTerm
	end tell
end run
APPLESCRIPT
