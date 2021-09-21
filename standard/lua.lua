---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lua
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = {}

function Lua.moduleExists(name)
	if package.loaded[name] then
		return true
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				-- luacheck: ignore
				-- luacheck complains about package.preload being read-only
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end

function Lua.requireIfExists(name, default)
	if Lua.moduleExists(name) then
		return require(name)
	else
		return default
	end
end

function Lua.loadDataIfExists(name, default)
	if Lua.moduleExists(name) then
		return mw.loadData(name)
	else
		return default
	end
end

-- options.requireDevIfEnabled:
-- Requires the development version of a module (with /dev appended to name) if
-- it exists and a certain development flag is enabled. Otherwise requires the
-- non-development module.
function Lua.import(name, options)
	options = options or {}
	if options.requireDevIfEnabled then
		local devName = name .. '/dev'
		if require('Module:DevFlags').matchGroupDev and Lua.moduleExists(devName) then
			return require(devName)
		else
			return require(name)
		end
	else
		return require(name)
	end
end

return Lua
