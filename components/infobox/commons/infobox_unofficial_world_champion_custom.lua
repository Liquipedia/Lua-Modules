---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local UnofficialWorldChampion = require('Module:Infobox/UnofficialWorldChampion')
local Class = require('Module:Class')

local CustomUnofficialWorldChampion = Class.new()

function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	return unofficialWorldChampion:createInfobox(frame)
end

return CustomUnofficialWorldChampion
