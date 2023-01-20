---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local GameLookup = require('Module:GameLookup')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomTeam.run(frame)
	local team = Team(frame)

	-- Automatic achievements
	team.args.achievements = Template.expandTemplate(frame, 'Team achievements', {team.pagename, aka = team.args.aka})

	-- Automatic org people
	team.args.coach = Template.expandTemplate(frame, 'Coach of')
	team.args.manager = Template.expandTemplate(frame, 'Manager of')
	team.args.captain = Template.expandTemplate(frame, 'Captain of')

	team.createWidgetInjector = CustomTeam.createWidgetInjector

	_args = team.args

	return team:createInfobox(frame)
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Games',
		content = _args.games and CustomTeam._getGames() or {}
	})
	return widgets
end

function CustomTeam._getGames()
	return Table.mapValues(Table.mapValues(mw.text.split(_args.games, ','), mw.text.trim), GameLookup.getName)
end

return CustomTeam
