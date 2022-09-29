---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomUnofficialWorldChampion = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	_args = unofficialWorldChampion.args
	unofficialWorldChampion.createWidgetInjector = CustomUnofficialWorldChampion.createWidgetInjector
	return unofficialWorldChampion:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	--Regional distribution
	if String.isNotEmpty(_args.region1) then
		table.insert(widgets, Title{name = 'Regional distribution'})
	end
	for regionKey, region in Table.iter.pairsByPrefix(_args, 'region') do
		table.insert(
			widgets,
			Cell{
				name = (_args[regionKey .. ' no'] or '') .. ' champions',
				content = {region},
			}
		)
		table.insert(
			widgets,
			Breakdown{content = {_args[regionKey .. ' champions']}}
		)
	end

	return widgets
end

function CustomUnofficialWorldChampion:createWidgetInjector()
	return CustomInjector()
end

return CustomUnofficialWorldChampion
