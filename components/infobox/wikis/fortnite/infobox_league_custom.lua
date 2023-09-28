---
-- @Liquipedia
-- wiki=fortnite
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Number of Players',
		content = {_args.player_number}
	})
	table.insert(widgets, Cell{
		name = 'Number of Teams',
		content = {_args.team_number}
	})

	return widgets
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_publishertier', args.epicpremier)
	--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.epicpremier)
end

return CustomLeague
