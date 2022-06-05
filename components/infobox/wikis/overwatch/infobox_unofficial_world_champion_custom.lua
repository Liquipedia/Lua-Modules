---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local UnofficialWorldChampion = require('Module:Infobox/UnofficialWorldChampion')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Breakdown = require('Module:Infobox/Widget/Breakdown')

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
