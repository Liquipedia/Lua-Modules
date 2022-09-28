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

local CustomUnofficialWorldChampion = Class.new()

function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	return unofficialWorldChampion:createInfobox(frame)
end

return CustomUnofficialWorldChampion
