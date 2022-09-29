---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

local _GAME = mw.loadData('Module:GameVersion')
local _MODES = mw.loadData('Module:GameModes')
local _FORMATS = mw.loadData('Module:GameFormats')

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args
	_args.format = CustomLeague:_getGameFormat()

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					CustomLeague._getGameVersion()
				}
			},
			Cell{name = 'Game mode', content = {
					CustomLeague:_getGameMode()
				}
			},
		}
	elseif id == 'customcontent' then
		if _args.player_number then
			table.insert(widgets, Title{name = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {_args.player_number}})
		elseif _args.team_number then
			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = CustomLeague._getGameVersion()
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.publishertier = args.pokemonpremier
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	Variables.varDefine('tournament_game', CustomLeague._getGameVersion())
	Variables.varDefine('tournament_publishertier', _args['pokemonpremier'])
	--Legacy Vars:
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague._getGameVersion()
	return _GAME[string.lower(_args.game or '')]
end

function CustomLeague:liquipediaTierHighlighted()
	return Logic.readBool(_args.pokemonpremier)
end

function CustomLeague:_getGameMode()
	if String.isEmpty(_args.mode) then
		return nil
	end

	return _MODES[_args.mode:lower()]
end

function CustomLeague:_getGameFormat()
	if String.isEmpty(_args.format) then
		return nil
	end

	return _FORMATS[_args.format:lower()]
end

return CustomLeague
