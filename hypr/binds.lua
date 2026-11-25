-- ZeeShell: autostart and default keybinds.
-- This file is yours. install.sh puts it in ~/.config/hypr/zeeshell/ once and
-- never overwrites it, so change the keys here, or use Settings -> Input -> Keybinds.
--
-- ZeeShell registers global shortcuts with Hyprland; a bind just points a key
-- at one of them. Available names: launcher, commands, sidebar, power, lock,
-- wallpaper, keybinds, settings, files, editWidgets, steam, randomWallpaper,
-- brightnessUp, brightnessDown, clipboard, overview, switcher, switcherBack,
-- switcherCommit.

local function zee(name)
	return hl.dsp.global("zeeshell:" .. name)
end

-- Start the shell with the session.
hl.on("hyprland.start", function()
	hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/zeeshell")
end)

local binds = {
	{ "SUPER + space", "launcher", "App drawer" },
	{ "SUPER + A", "sidebar", "Quick settings" },
	{ "SUPER + E", "files", "File explorer" },
	{ "SUPER + L", "lock", "Lock the session" },
	{ "SUPER + Escape", "power", "Power menu" },
	{ "SUPER + slash", "keybinds", "Keybinding cheat sheet" },
	{ "SUPER + comma", "settings", "ZeeShell settings" },
	{ "SUPER + SHIFT + W", "wallpaper", "Wallpaper picker" },
	{ "SUPER + V", "clipboard", "Clipboard history" },
	{ "SUPER + Tab", "overview", "Window overview" },
	{ "ALT + Tab", "switcher", "Switch windows" },
	{ "ALT + SHIFT + Tab", "switcherBack", "Switch windows backwards" },
	{ "XF86MonBrightnessUp", "brightnessUp", "Increase brightness" },
	{ "XF86MonBrightnessDown", "brightnessDown", "Decrease brightness" },
}

for _, b in ipairs(binds) do
	-- Binding a combo twice makes both actions fire, so release it first.
	-- Delete the next three lines if you would rather keep what the key did.
	for _ = 1, 4 do
		hl.unbind(b[1])
	end
	hl.bind(b[1], zee(b[2]), { description = b[3] })
end

-- Alt-Tab switches when Alt is let go. The release still reaches apps.
hl.bind("ALT + ALT_L", zee("switcherCommit"), { release = true, transparent = true, non_consuming = true })
