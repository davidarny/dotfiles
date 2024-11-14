THEME.git = THEME.git or {}
THEME.git.modified = ui.Style():fg("blue")
THEME.git.added = ui.Style():fg("green"):bold()
THEME.git.untracked = ui.Style():fg("yellow"):bold()
THEME.git.ignored = ui.Style():fg("cyan"):bold()
THEME.git.deleted = ui.Style():fg("red"):bold()
THEME.git.updated = ui.Style():fg("magenta"):bold()

THEME.git.modified_sign = "󱇧"
THEME.git.added_sign = ""
THEME.git.untracked_sign = ""
THEME.git.ignored_sign = "◌"
THEME.git.deleted_sign = ""
THEME.git.updated_sign = "❖"
require("git"):setup()

require("full-border"):setup()
