---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	_player = player

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	_args = player.args
	_args.autoTeam = true

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'history' then
		local manualHistory = _args.history
		local automatedHistory = TeamHistoryAuto._results{
			convertrole = true,
			player = _player.pagename,
			addlpdbdata = true
		}

		if manualHistory or automatedHistory then
			return {
				Title{name = 'History'},
				Center{content = {manualHistory}},
				Center{content = {automatedHistory}},
			}
		end
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {Role.run({role = _args.role}).display, Role.run({role = _args.role2}).display}}
		}
	end
	return widgets
end

function CustomInjector:addCustomCells()
	local widgets = {Cell{name = 'Abbreviations', content = {_args.abbreviations}}}
	local statisticsCells = {
		races = {order = 1, name = 'Races'},
		wins = {order = 2, name = 'Wins'},
		podiums = {order = 3, name = 'Podiums'},
		poles = {order = 4, name = 'Pole positions'},
		fastestlaps = {order = 5, name = 'Fastest Laps'},
		points = {order = 6, name = 'Career Points'},
		firstrace = {order = 7, name = 'First race'},
		lastrace = {order = 8, name = 'Last race'},
		firstwin = {order = 9, name = 'First win'},
		lastwin = {order = 10, name = 'Last win'},
		salary = {order = 11, name = 'Reported Salary'},
		contract = {order = 12, name = 'Current Contract'},
	}
	if Table.any(_args, function(key) return statisticsCells[key] end) then
		table.insert(widgets, Title{name = 'Driver Statistics'})
		local statisticsCellsOrder = function(tbl, a, b) return tbl[a].order < tbl[b].order end
		for key, item in Table.iter.spairs(statisticsCells, statisticsCellsOrder) do
			table.insert(widgets, Cell{name = item.name, content = {_args[key]}})
		end
	end

	return widgets
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData, args)
	local role = Role.run{role = args.role}
	lpdbData.extradata.isplayer = role.isPlayer or 'true'
	lpdbData.extradata.role = role.role
	lpdbData.extradata.role2 = Role.run{role = args.role2}.role
	return lpdbData
end

return CustomPlayer
