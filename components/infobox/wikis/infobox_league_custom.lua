---
-- @Liquipedia
-- wiki=pokemon
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Logic = require('Module:Logic')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _game

local _GAME = mw.loadData('Module:GameVersion')
local _MODES = mw.loadData('Module:GameModes')
local _FORMATS = mw.loadData('Module:GameFormats')

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
			Cell{name = 'Format', content = {
					CustomLeague:_getGameFormat()
				}
			},
		}
	elseif id == 'customcontent' then
		if _args.player_number then
			table.insert(widgets, Title{name = 'Players'})
			table.insert(widgets, Cell{name = 'Number of players', content = {_args.player_number}})
		end

		--teams section
		if _args.team_number then
			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = args.game
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.publishertier = args.pokemonpremier
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:defineCustomPageVariables()
	Variables.varDefine('tournament_game', _game or _args.game)
	Variables.varDefine('tournament_publishertier', _args['pokemonpremier'])
	--Legacy Vars:
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
end

function CustomLeague._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
end

function CustomLeague:liquipediaTierHighlighted()
	return Logic.readBool(_args.pubgpremier)
end

function CustomLeague:_getGameMode()
	if String.isEmpty(_args.mode) then
		return nil
	end
	local mode = _MODES[string.lower(_args.mode or '')] or _MODES['default']
	return mode
end

function CustomLeague:_getGameFormat()
	if String.isEmpty(_args.format) then
		return nil
	end

	local format = string.lower(_args.format or '')

	return _FORMATS[format] or _FORMATS['default']
end

return CustomLeague
