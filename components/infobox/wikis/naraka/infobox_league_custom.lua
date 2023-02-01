---
-- @Liquipedia
-- wiki=naraka
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

local _MODES = {
	solo = 'Solo[[Category:Solo Mode Tournaments]]',
	trio = 'Trios[[Category:Trios Mode Tournaments]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}
_MODES.solos = _MODES.solo
_MODES.trios = _MODES.trio

function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args
	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	return league:createInfobox()
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
		elseif _args.team_number then
			table.insert(widgets, Title{name = 'Teams'})
			table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		end
	end
	return widgets
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = args.platform
	lpdbData.participantsnumber = args.player_number or args.team_number
	lpdbData.publishertier = args.narakapremier

	lpdbData.extradata.individual = String.isNotEmpty(args.player_number)

	return lpdbData
end

function CustomLeague:_getGameMode()
	if String.isEmpty(_args.mode) then
		return nil
	end

	return _MODES[_args.mode:lower()] or _MODES['default']
end

return CustomLeague
