---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
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

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {_args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {_args.player_number}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {Game.name{game = _args.game}}},
		}
	end

	return widgets
end

function CustomLeague:liquipediaTierHighlighted()
	return Logic.readBool(_args.publisherpremier)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.extradata.individual = String.isNotEmpty(args.player_number) and 'true' or ''

	return lpdbData
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_publishertier', Logic.readBool(args.publisherpremier) and 'true' or nil)
end

return CustomLeague
