---@since 26.5.6

local function is_git_file(url)
	local file = io.open(tostring(url))
	if not file then
		return false
	end

	local head = file:read(8)
	file:close()
	return head == "gitdir: "
end

local function has_git_marker(url)
	local dotgit = url:join(".git")
	local cha = fs.cha(dotgit)
	return cha and (cha.is_dir or is_git_file(dotgit))
end

local function add_status(info, status)
	if status == "M" or status == "T" or status == "R" then
		info.modified = true
	elseif status == "A" or status == "C" then
		info.added = true
	elseif status == "D" then
		info.deleted = true
	elseif status == "U" then
		info.updated = true
	end
end

local function parse_status(stdout)
	local branch, oid, ahead, behind
	local info = {}
	for line in stdout:gmatch("[^\r\n]+") do
		branch = branch or line:match("^# branch%.head (.+)$")
		oid = oid or line:match("^# branch%.oid (.+)$")

		local ahead_count, behind_count = line:match("^# branch%.ab %+(%d+) %-(%d+)$")
		ahead = ahead or tonumber(ahead_count)
		behind = behind or tonumber(behind_count)

		local kind = line:sub(1, 1)
		if kind == "?" then
			info.untracked = true
		elseif kind == "u" then
			info.updated = true
		elseif kind == "1" or kind == "2" then
			local xy = line:match("^[12] ([^ ]+)")
			if xy then
				for i = 1, #xy do
					add_status(info, xy:sub(i, i))
				end
			end
		end
	end

	if branch == "(detached)" then
		branch = oid and "@" .. oid:sub(1, 7) or "HEAD"
	end
	if not branch then
		return
	end

	info.branch = branch
	info.ahead = ahead and ahead > 0
	info.behind = behind and behind > 0
	return info
end

local function inspect_repo(url)
	local output = Command("git")
		:cwd(tostring(url))
		:arg({
			"--no-optional-locks",
			"status",
			"--porcelain=v2",
			"--branch",
			"--untracked-files=normal",
			"--no-renames",
			"--ignore-submodules=dirty",
		})
		:output()

	return output and parse_status(output.stdout)
end

local apply = ya.sync(function(st, parent, updates)
	if tostring(cx.active.current.cwd) ~= parent then
		return
	end

	local changed = st.parent ~= parent
	if changed then
		st.parent = parent
		st.repos = {}
	end

	for url, info in pairs(updates) do
		local old = st.repos[url]
		if not info then
			if old then
				st.repos[url] = nil
				changed = true
			end
		elseif not old
			or old.branch ~= info.branch
			or old.ahead ~= info.ahead
			or old.behind ~= info.behind
			or old.untracked ~= info.untracked
			or old.modified ~= info.modified
			or old.added ~= info.added
			or old.deleted ~= info.deleted
			or old.updated ~= info.updated
		then
			st.repos[url] = info
			changed = true
		end
	end

	if changed then
		ui.render()
	end
end)

local function setup(st, opts)
	st.repos = {}
	opts = opts or {}

	local default_branch = ui.Style():fg("darkgray")
	local branch = ui.Style():fg("cyan")
	local signs = {
		{ "ahead", "↑", ui.Style():fg("green") },
		{ "behind", "↓", ui.Style():fg("cyan") },
		{ "untracked", "?", ui.Style():fg("magenta") },
		{ "modified", "", ui.Style():fg("yellow") },
		{ "added", "", ui.Style():fg("green") },
		{ "deleted", "", ui.Style():fg("red") },
		{ "updated", "", ui.Style():fg("yellow") },
	}

	Linemode:children_add(function(self)
		local file = self._file
		if not file.in_current or not file.cha.is_dir then
			return ""
		end

		local info = st.repos[tostring(file.url)]
		if not info then
			return ""
		end

		local plain = info.branch
		local is_default = info.branch == "master" or info.branch == "main"
		local chunks = { " ", ui.Span(info.branch):style(is_default and default_branch or branch) }
		for _, sign in ipairs(signs) do
			if info[sign[1]] and not (sign[1] == "updated" and info.modified) then
				plain = plain .. " " .. sign[2]
				chunks[#chunks + 1] = " "
				chunks[#chunks + 1] = ui.Span(sign[2]):style(sign[3])
			end
		end

		if file.is_hovered then
			return ui.Line { " ", plain }
		end
		return ui.Line(chunks)
	end, opts.order or 1600)
end

---@type UnstableFetcher
local function fetch(_, job)
	local first = job.files[1]
	if not first then
		return true
	end

	local parent_url = first.url.base or first.url.parent
	local parent = tostring(parent_url)
	local updates, state = {}, {}

	for i, file in ipairs(job.files) do
		local url = tostring(file.url)
		if file.cha.is_dir and has_git_marker(file.url) then
			updates[url] = inspect_repo(file.url) or false
			state[i] = false
		else
			updates[url] = false
			state[i] = true
		end
	end

	apply(parent, updates)
	return state
end

return { setup = setup, fetch = fetch }
