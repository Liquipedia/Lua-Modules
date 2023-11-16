---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TeamTemplates = require('Module:Team')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)
local Chronology = Widgets.Chronology

local _args
local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_args = _team.args

	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories
	return team:createInfobox()
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells()
	local widgets = {}
	local statisticsCells = {
		races = {order = 1, name = 'Races'},
		wins = {order = 2, name = 'Wins'},
		podiums = {order = 3, name = 'Podiums'},
		poles = {order = 4, name = 'Pole positions'},
		fastestlaps = {order = 5, name = 'Fastest Laps'},
		points = {order = 6, name = 'Career Points'},
		firstentry = {order = 7, name = 'First entry'},
		firstwin = {order = 8, name = 'First win'},
		lastentry = {order = 9, name = 'Last entry'},
	}
	if Table.any(_args, function(key) return statisticsCells[key] end) then
		table.insert(widgets, Title{name = 'Team Statistics'})
		local statisticsCellsOrder = function(tbl, a, b) return tbl[a].order < tbl[b].order end
		for key, item in Table.iter.spairs(statisticsCells, statisticsCellsOrder) do
			table.insert(widgets, Cell{name = item.name, content = {_args[key]}})
		end
	end

	if _args.academy then
		local academyTeams = Array.map(_team:getAllArgsForBase(_args, 'academy'), function(team)
			return TeamTemplates.team(nil, team)
		end)
		Array.extendWith(widgets,
			{Title{name = 'Academy Team' .. (Table.size(academyTeams) > 1 and 's' or '')}},
			Array.map(academyTeams, function(academyTeam) return Center{content = {academyTeam}} end)
		)
	end

	if _args.previous or _args.next then
		Array.appendWith(
			widgets,
			Title{name = 'Chronology'},
			Chronology{content = {
				previous = _args.previous,
				previous2 = _args.previous2,
				next = _args.next,
				next2 = _args.next2,
			}}
		)
	end

	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata = lpdbData.extradata or {}
	lpdbData.extradata.previous = args.previous
	lpdbData.extradata.previous2 = args.previous2
	lpdbData.extradata.next = args.next
	lpdbData.extradata.next2 = args.next2

	return lpdbData
end

return CustomTeam
