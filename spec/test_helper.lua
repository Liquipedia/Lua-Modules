-- luacheck: ignore

-- Copy from standard/lua.lua
local function fileExists(name)
	if package.loaded[name] then
		return true
	else
		-- Package.Searchers was renamed from Loaders in lua5.2, have support for both
		---@diagnostic disable-next-line: deprecated
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name)
			if type(loader) == 'function' then
				package.preload[name] = loader
				return true
			end
		end
		return false
	end
end


mw = {
	loadData = function(module)
		-- Should be expanded with a Meta Table that disallows __index
		return require(module)
	end,
	log = function() end,
	logObject = function() end,
	getContentLanguage = function()
		return {
			formatNum = function(self, amount)
				local k
				local formatted = amount
				while true do
					formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
					if (k == 0) then
						break
					end
				end
				return formatted
			end
		}
	end,
}
mw.ext = {}
local variablesStorage = {}
mw.ext.VariablesLua = {
	vardefine = function(name, value)
		variablesStorage[name] = tostring(value)
		return ''
	end,
	vardefineecho = function(name, value)
		variablesStorage[name] = tostring(value)
		return variablesStorage[name]
	end,
	var = function(name) return variablesStorage[name] end,
}
mw.ext.CurrencyExchange = {
	currencyexchange = function(amount, fromCurrency, toCurrency, date) return 0.97097276906869 end
}
local function resetMediawiki()
	variablesStorage = {}
end

local function mockRequire()
	package.path = '?.lua;' ..
			'standard/?.lua;' .. -- Load std folder
			package.path

	local require_original = require
	local Plugin = require_original('plugins.sumneko_plugin')

	function require(module)
		local newName = module
		if (string.find(module, 'Module:')) then
			newName = Plugin.luaifyModuleName(module)
		end

		if fileExists(newName) then
			return require_original(newName)
		end

		if newName == 'info' then
			return require_original('info.commons.info')
		end

		-- Just apply a fake function that returns the first input, as something
		local mocked_import = {}
		setmetatable(mocked_import, {
			__index = function(t, k)
				return function(v) return v end
			end
		})

		print('Could not find ' .. newName)
		return mocked_import
	end
end


require('busted').subscribe({'suite', 'start'}, mockRequire)
require('busted').subscribe({'test', 'start'}, resetMediawiki)
