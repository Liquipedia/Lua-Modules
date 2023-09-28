---
-- @Liquipedia
-- wiki=freefire
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

--TODO: Seperate categories
local MODES = {
	solo = 'Solos[[Category:Solos Mode Tournaments]]',
	['solo rh'] = 'Solos Rush Hour [[Category:Solos Rush Hour Mode Tournaments]]',
	duo = 'Duos[[Category:Duos Mode Tournaments]]',
	squad = 'Squads[[Category:Squads Mode Tournaments]]',
	['4v4'] = '4v4 Clash Squad[[Category:4v4 Clash Squad Tournaments]]',
	['4v4b'] = '4v4 Bomb Squad [[Category:4v4 Bomb Squad Tournaments]]',
	['5v5'] = '5v5 Bomb Squad [[Category:5v5 Bomb Squad Tournaments]]',
	['6v6'] = '6v6 Clash Squad [[Category:6v6 Clash Squad Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables

	return league:createInfobox()
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

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game Mode', content = {CustomLeague._getGameMode(_args.mode)}},
		}
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague._getGameMode(mode)
	if String.isEmpty(mode) then
		return
	end

	return MODES[mode:lower()]
end

return CustomLeague
