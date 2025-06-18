---
-- @Liquipedia
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion')

---@class CustomUnofficialWorldChampionInfobox: UnofficialWorldChampionInfobox
local CustomUnofficialWorldChampion = Class.new(UnofficialWorldChampion)

---@param frame Frame
---@return Html
function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = CustomUnofficialWorldChampion(frame)
	return unofficialWorldChampion:createInfobox()
end

return CustomUnofficialWorldChampion
