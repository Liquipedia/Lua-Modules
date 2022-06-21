---
-- @Liquipedia
-- wiki=naraka
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local Template = require('Module:Template')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Table = require('Module:Table')
local Logic = require('Module:Logic')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

local _MODES = {
	solo = 'Solo[[Category:Solo Mode Tournaments]]',
	trio = 'Trios[[Category:Trios Mode Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}
_MODES.solos = _MODES.solo
_MODES.trio = _MODES.trios

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
			Cell{name = 'Game mode', content = {
					CustomLeague:_getGameMode()
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
	lpdbData.game = args.platform
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.publishertier = args.pubgpremier
	lpdbData.extradata = {
		individual = String.isNotEmpty(args.player_number) and 'true' or '',
	}

	return lpdbData
end

function CustomLeague:_getGameMode()
	if String.isEmpty(_args.perspective) and String.isEmpty(_args.mode) then
		return nil
	end

	local mode = _MODES[string.lower(_args.mode or '')] or _MODES['default']

	return mode 
end


return CustomLeague
