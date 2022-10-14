---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
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
local _GAME = mw.loadData('Module:GameVersion')

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
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
			Cell{name = 'Game version', content = {CustomLeague._getGameVersion()}},
		}
	end

	return widgets
end

function CustomLeague:liquipediaTierHighlighted()
	return Logic.readBool(_args['publisherpremier'])
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = CustomLeague._getGameVersion()
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.publishertier = Logic.readBool(_args.publisherpremier) or nil
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	Variables.varDefine('tournament_game', CustomLeague._getGameVersion())
	Variables.varDefine('tournament_publishertier', _args['publisherpremier'])
end

function CustomLeague._getGameVersion()
	return _GAME[string.lower(_args.game or '')]
end

return CustomLeague
