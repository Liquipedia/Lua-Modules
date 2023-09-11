---
-- @Liquipedia
-- wiki=tft
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local GAME_MODES = {
	solo = 'Solos',
	duo = 'Duos',
	squad = 'Squads',
}
local DEFAULT_MODE = GAME_MODES.solo
local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Tournament supported by Riot Games]]'

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args
	_args.mode = _args.mode and GAME_MODES[string.lower(_args.mode):gsub('s$', '')] or DEFAULT_MODE -- Normalize Mode input

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Teams',
		content = {args.team_number}
	})
	table.insert(widgets, Cell{
		name = 'Players',
		content = {args.participants_number}
	})
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Game',
			content = {Game.name{game = _args.game}}
		})
		table.insert(widgets, Cell{
			name = 'Patch',
			content = {CustomLeague:_createPatchCell(_args)}
		})
		table.insert(widgets, Cell{
			name = 'Game Mode',
			content = {_args.mode}
		})
	end

	return widgets
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args['riot-sponsored'])
end

function CustomLeague:appendLiquipediatierDisplay(args)
	if Logic.readBool(args['riot-sponsored']) then
		return ' ' .. RIOT_ICON
	end
	return ''
end

function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_mode', string.lower(args.mode or ''))
end

function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end

	local content = '[[Patch ' .. args.patch .. '|'.. args.patch .. ']]'

	if String.isEmpty(args.epatch) then
		return content
	end

	return content .. ' &ndash; [[Patch ' .. args.epatch .. '|'.. args.epatch .. ']]'
end

function CustomLeague:getWikiCategories(args)
	return {args.mode .. ' Mode Tournaments'}
end
return CustomLeague
