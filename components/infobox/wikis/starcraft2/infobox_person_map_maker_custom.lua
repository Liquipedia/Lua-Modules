---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/MapMaker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local CustomPerson = Lua.import('Module:Infobox/Person/Custom', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomMapMaker = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _map_maker

function CustomMapMaker.run(frame)
	local mapMaker = CustomPerson(frame)
	_map_maker = mapMaker
	_args = mapMaker.args

	mapMaker.calculateEarnings = CustomMapMaker.calculateEarnings
	mapMaker.createBottomContent = CustomMapMaker.createBottomContent
	mapMaker.createWidgetInjector = CustomMapMaker.createWidgetInjector

	return mapMaker:createInfobox()
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {_map_maker:getRaceData(_args.race or 'unknown')}
			}
		}
	elseif id == 'role' then return {}
	elseif id == 'region' then return {}
	elseif id == 'achievements' then
		if String.isNotEmpty(_args.maps_ladder) or String.isNotEmpty(_args.maps_special) then
			return {
				Title{name = 'Achievements'},
				Cell{name = 'Ladder maps created', content = {_args.maps_ladder}},
				Cell{name = 'Non-ladder competitive maps created', content = {_args.maps_special}}
			}
		end
		return {}
	elseif
		id == 'history' and
		string.match(_args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {_args.retired}
			})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Military Service', content = {_args.military}},
	}
end

function CustomMapMaker:createWidgetInjector()
	return CustomInjector()
end

return CustomMapMaker
