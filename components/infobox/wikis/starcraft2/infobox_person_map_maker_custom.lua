---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Person/MapMaker/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local PersonSc2 = require('Module:Infobox/Person/Custom/Shared')
local Person = require('Module:Infobox/Person')
local String = require('Module:StringUtils')
local Class = require('Module:Class')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')

local CustomMapMaker = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomMapMaker.run(frame)
	local player = Person(frame)
	_args = player.args
	PersonSc2.setArgs(_args)

	player.shouldStoreData = PersonSc2.shouldStoreData
	player.getStatusToStore = PersonSc2.getStatusToStore
	player.adjustLPDB = PersonSc2.adjustLPDB
	player.getPersonType = PersonSc2.getPersonType
	player.nameDisplay = PersonSc2.nameDisplay

	player.calculateEarnings = CustomMapMaker.calculateEarnings
	player.createBottomContent = CustomMapMaker.createBottomContent
	player.createWidgetInjector = CustomMapMaker.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'status' then
		return {
			Cell{
				name = 'Race',
				content = {PersonSc2.getRaceData(_args.race or 'unknown')}
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
		Cell{name = 'Military Service', content = {PersonSc2.military(_args.military)}},
	}
end

function CustomMapMaker:createWidgetInjector()
	return CustomInjector()
end



return CustomMapMaker
