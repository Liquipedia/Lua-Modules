---
-- @Liquipedia
-- page=Module:MapMode
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Data = Lua.import('Module:MapMode/Data', {loaddata = true})

local MapMode = {}

---@param input string?
---@return string?
function MapMode.getKey(input)
	if Logic.isEmpty(input) then
		return
	end

	---@cast input string
	local lowered = string.lower(mw.text.trim(input))
	local key = Data.aliases[lowered] or lowered

	if Data.mode[key] then
		return key
	end
end

---@param key string?
---@return {display: string, link: string}?
function MapMode.getData(key)
	return key and Data.mode[key] or nil
end

return MapMode
