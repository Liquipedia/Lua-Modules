---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local UnofficialWorldChampion = require('Module:Infobox/UnofficialWorldChampion')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')

local CustomUnofficialWorldChampion = Class.new()

local CustomInjector = Class.new(Injector)

function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	unofficialWorldChampion.createWidgetInjector = CustomUnofficialWorldChampion.createWidgetInjector
	return unofficialWorldChampion:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
  return widgets
end

function CustomUnofficialWorldChampion:createWidgetInjector()
	return CustomInjector()
end

return CustomUnofficialWorldChampion
