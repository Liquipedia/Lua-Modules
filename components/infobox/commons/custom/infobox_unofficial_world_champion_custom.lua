---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion', {requireDevIfEnabled = true})

---@class CustomUnofficialWorldChampionInfobox: UnofficialWorldChampionInfobox
local CustomUnofficialWorldChampion = Class.new()

---@param frame Frame
---@return Html
function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	return unofficialWorldChampion:createInfobox()
end

return CustomUnofficialWorldChampion
