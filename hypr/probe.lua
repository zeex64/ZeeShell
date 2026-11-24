-- ZeeShell keybind recorder.
--
-- Hyprland does not report what a Lua-configured bind does (hyprctl only shows
-- an opaque reference), so ZeeShell's keybind editor could not move or copy an
-- existing bind. This file is loaded first (install.sh adds the line to
-- hyprland.lua) and watches hl.bind / hl.unbind and the hl.dsp.* constructors
-- as the rest of the config runs. At the end of the config it writes what it
-- saw to ~/.cache/zeeshell/hypr-binds.json.
--
-- It only observes: every call is passed straight through. Any failure in here
-- is swallowed so it can never break the config.

pcall(function()
	-- The Lua state can outlive a reload; undo the previous wrapping first.
	local keep = rawget(_G, "__zeeshell_keep")
	if keep then
		for _, e in ipairs(keep.fns) do
			e[1][e[2]] = e[3]
		end
		hl.bind = keep.bind
		hl.unbind = keep.unbind
	end
	keep = { bind = hl.bind, unbind = hl.unbind, fns = {} }
	rawset(_G, "__zeeshell_keep", keep)

	local rec = { binds = {} }
	rawset(_G, "zeeshell_binds", rec)

	-- dispatcher object -> how it was built
	local built = setmetatable({}, { __mode = "k" })

	-- Lua source for a plain value; nil if it contains a function or userdata.
	local function source(v, depth)
		depth = depth or 0
		local t = type(v)
		if t == "string" then
			return string.format("%q", v)
		elseif t == "number" or t == "boolean" or t == "nil" then
			return tostring(v)
		elseif t == "table" and depth < 6 then
			local parts, n = {}, #v
			for i = 1, n do
				local s = source(v[i], depth + 1)
				if not s then
					return nil
				end
				parts[#parts + 1] = s
			end
			local keys = {}
			for k in pairs(v) do
				if not (type(k) == "number" and k >= 1 and k <= n and k % 1 == 0) then
					keys[#keys + 1] = k
				end
			end
			table.sort(keys, function(a, b)
				return tostring(a) < tostring(b)
			end)
			for _, k in ipairs(keys) do
				local s = source(v[k], depth + 1)
				if not s then
					return nil
				end
				if type(k) == "string" and k:match("^[%a_][%w_]*$") then
					parts[#parts + 1] = k .. " = " .. s
				else
					local ks = source(k, depth + 1)
					if not ks then
						return nil
					end
					parts[#parts + 1] = "[" .. ks .. "] = " .. s
				end
			end
			return #parts == 0 and "{}" or ("{ " .. table.concat(parts, ", ") .. " }")
		end
		return nil
	end

	local function wrap(tbl, path)
		local names = {}
		for k, v in pairs(tbl) do
			names[#names + 1] = { k, v }
		end
		for _, e in ipairs(names) do
			local k, v = e[1], e[2]
			if type(v) == "function" then
				keep.fns[#keep.fns + 1] = { tbl, k, v }
				local name = path .. "." .. tostring(k)
				tbl[k] = function(...)
					local r = v(...)
					if r ~= nil then
						local n, a = select("#", ...), { ... }
						pcall(function()
							local args, plain = {}, true
							for i = 1, n do
								local s = source(a[i])
								if not s then
									plain = false
									break
								end
								args[i] = s
							end
							built[r] = {
								fn = name,
								lua = plain and (name .. "(" .. table.concat(args, ", ") .. ")") or nil,
								arg = type(a[1]) == "string" and a[1] or nil,
							}
						end)
					end
					return r
				end
			elseif type(v) == "table" then
				wrap(v, path .. "." .. tostring(k))
			end
		end
	end
	wrap(hl.dsp, "hl.dsp")

	-- "SUPER + Shift + w" and "shift+SUPER+W" are the same combo.
	local function norm(combo)
		local mods, key = {}, ""
		local parts = {}
		for p in tostring(combo):gmatch("[^+]+") do
			parts[#parts + 1] = (p:gsub("^%s+", ""):gsub("%s+$", ""))
		end
		for i, p in ipairs(parts) do
			if i == #parts then
				key = p:lower()
			else
				mods[#mods + 1] = p:upper()
			end
		end
		table.sort(mods)
		return table.concat(mods, "+") .. "|" .. key
	end

	local function where()
		local info = debug and debug.getinfo and debug.getinfo(3, "Sl")
		if not info then
			return ""
		end
		-- Keep the folder too ("lua/binds.lua"), so files with the same name stay apart.
		local path = info.short_src or "?"
		return (path:match("([^/]+/[^/]+)$") or path) .. ":" .. tostring(info.currentline or 0)
	end

	hl.bind = function(combo, action, opts, ...)
		local src = where()
		pcall(function()
			local b = built[action]
			local flags = {}
			local desc = ""
			if type(opts) == "table" then
				local keys = {}
				for k in pairs(opts) do
					keys[#keys + 1] = k
				end
				table.sort(keys, function(x, y)
					return tostring(x) < tostring(y)
				end)
				for _, k in ipairs(keys) do
					if k == "description" then
						desc = tostring(opts[k])
					else
						local s = source(opts[k])
						if s and type(k) == "string" then
							flags[#flags + 1] = k .. " = " .. s
						end
					end
				end
			end
			rec.binds[#rec.binds + 1] = {
				combo = tostring(combo),
				key = norm(combo),
				fn = b and b.fn or (type(action) == "function" and "function" or "unknown"),
				lua = b and b.lua or nil,
				arg = b and b.arg or nil,
				desc = desc,
				flags = table.concat(flags, ", "),
				src = src,
				active = true,
			}
		end)
		return keep.bind(combo, action, opts, ...)
	end

	hl.unbind = function(combo, ...)
		pcall(function()
			local key = norm(combo)
			for _, b in ipairs(rec.binds) do
				if b.active and b.key == key then
					b.active = false
				end
			end
		end)
		return keep.unbind(combo, ...)
	end

	local function json(s)
		return '"'
			.. tostring(s):gsub('[%c"\\]', function(c)
				if c == '"' then
					return '\\"'
				elseif c == "\\" then
					return "\\\\"
				elseif c == "\n" then
					return "\\n"
				end
				return string.format("\\u%04x", c:byte())
			end)
			.. '"'
	end

	-- Called from the last line of hyprland.lua.
	rec.dump = function()
		pcall(function()
			local dir = (os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")) .. "/zeeshell"
			local out = {}
			for i, b in ipairs(rec.binds) do
				out[i] = "{"
					.. '"combo":' .. json(b.combo)
					.. ',"fn":' .. json(b.fn)
					.. ',"lua":' .. (b.lua and json(b.lua) or "null")
					.. ',"arg":' .. (b.arg and json(b.arg) or "null")
					.. ',"desc":' .. json(b.desc)
					.. ',"flags":' .. json(b.flags)
					.. ',"src":' .. json(b.src)
					.. ',"active":' .. tostring(b.active)
					.. "}"
			end
			local f = io.open(dir .. "/hypr-binds.json", "w")
			if not f then
				return
			end
			f:write("[\n" .. table.concat(out, ",\n") .. "\n]\n")
			f:close()
		end)
	end
end)
