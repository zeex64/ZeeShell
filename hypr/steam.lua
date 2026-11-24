-- ZeeShell: Steam workspace (optional).
-- Steam lives in its own special workspace: its windows always open there
-- (silently, so nothing pops up), Steam starts with the session, and
-- SUPER + G drops the workspace over whatever you are doing.
-- Off until you turn it on in Settings -> Modules -> Steam workspace.

local NAME = "steam"
local SPECIAL = "special:" .. NAME
local CLASS = "steam" -- window class of the Steam client
local COMMAND = "steam"

-- Settings writes flags.lua next to this file. Without it, this stays off.
local flags = {}
pcall(function()
	local dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/zeeshell/"
	flags = dofile(dir .. "flags.lua").steam or {}
end)
if flags.enabled ~= true then
	return
end

local GAP = 40 -- space around the workspace so the desktop shows behind it
local FILL = tonumber(flags.fill) or 0.88 -- share of the monitor's width Steam takes on a wide monitor
local WIDE = 2560 -- monitors no wider than this always get the full width
local FRIENDS = tonumber(flags.friends) or 0.25 -- share of the workspace the Friends List column gets

-- Steam's windows belong to the special workspace, wherever they are opened from.
hl.window_rule({
	name = "steam-workspace",
	match = { class = "^(" .. CLASS .. ")$" },
	workspace = SPECIAL .. " silent",
})

-- Look: framed by a gap, desktop dimmed and blurred behind, slides in from the top.
-- The side gaps are worked out per monitor, so Steam stays a sensible width on
-- an ultrawide and still fills a small screen.
local function fit(mon)
	local side = GAP
	if mon and mon.width then
		local width = mon.width / (mon.scale or 1)
		if width > WIDE then
			side = math.max(GAP, math.floor(width * (1 - FILL) / 2))
		end
	end
	hl.workspace_rule({ workspace = SPECIAL, gaps_out = { top = GAP, right = side, bottom = GAP, left = side } })
end
pcall(function()
	fit(hl.get_active_monitor())
end)
pcall(function()
	hl.config({
		decoration = {
			dim_special = 0.45,
			blur = { special = true },
		},
	})
	hl.curve("zeeshellSettle", { type = "bezier", points = { { 0.2, 0 }, { 0, 1 } } })
	hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "zeeshellSettle", style = "slidefadevert -25%" })
end)

-- Start Steam with the session. The rule above keeps it out of sight.
hl.on("hyprland.start", function()
	if flags.autostart ~= false then
		hl.exec_cmd(COMMAND)
	end
end)

local function steam_window_count()
	local n = 0
	for _, w in pairs(hl.get_windows()) do
		if w.class == CLASS then
			n = n + 1
		end
	end
	return n
end

-- Give the Friends List a narrow column instead of half the workspace.
-- Dwindle splits 50/50 when it opens; this sets the left-hand window of the
-- pair to its share (an exact resize is only reliable on the left one).
local function balance()
	pcall(function()
		local main, friends
		for _, w in pairs(hl.get_windows()) do
			if w.class == CLASS and not w.floating and w.workspace and w.workspace.name == SPECIAL then
				if w.title == "Friends List" then
					friends = w
				elseif w.title == "Steam" then
					main = w
				end
			end
		end
		if not main or not friends then
			return
		end
		-- Only handle the plain side-by-side pair.
		if math.abs(main.at.y - friends.at.y) > 4 then
			return
		end
		local total = main.size.x + friends.size.x
		local want = math.floor(total * FRIENDS)
		if math.abs(friends.size.x - want) < total * 0.02 then
			return
		end
		if main.at.x < friends.at.x then
			hl.dispatch(hl.dsp.window.resize({ window = main, x = total - want, y = main.size.y, exact = true }))
		else
			hl.dispatch(hl.dsp.window.resize({ window = friends, x = want, y = friends.size.y, exact = true }))
		end
	end)
end
_G.steam_workspace_balance = balance

local function is_shown()
	local s = hl.get_active_special_workspace()
	return s ~= nil and s.name == SPECIAL
end

-- Show / hide. If Steam has no window (closed to tray, or not running), ask
-- it for one first so the workspace is never empty.
local function toggle()
	if not is_shown() then
		fit(hl.get_active_monitor())
		if steam_window_count() == 0 then
			hl.exec_cmd(COMMAND)
		end
	end
	hl.dispatch(hl.dsp.workspace.toggle_special(NAME))
end

-- ZeeShell's bar button calls this through `hyprctl eval`.
_G.steam_workspace_toggle = toggle

for _ = 1, 4 do
	hl.unbind("SUPER + G")
end
hl.bind("SUPER + G", toggle, { description = "Steam workspace" })

-- The workspace holds Steam only. Anything else that opens inside it (a game
-- you just launched) moves to the monitor's normal workspace, and the Steam
-- workspace gets out of the way.
hl.on("window.open", function(w)
	pcall(function()
		if not w then
			return
		end
		if w.class == CLASS then
			-- A Steam window arrived; once it has settled, fix the friends column.
			hl.timer(balance, { timeout = 500, type = "oneshot" })
			return
		end
		local ws = w.workspace
		if not ws or ws.name ~= SPECIAL then
			return
		end
		local mon = w.monitor or hl.get_active_monitor()
		local target = mon and mon.active_workspace
		if not target or not target.id then
			return
		end
		hl.dispatch(hl.dsp.window.move({ workspace = tostring(target.id), window = w }))
		if is_shown() then
			hl.dispatch(hl.dsp.workspace.toggle_special(NAME))
		end
	end)
end)
