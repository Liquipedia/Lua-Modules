---
-- @Liquipedia
-- wiki=osu
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

local _MODES = {
	standard = 'Standard[[Category:osu!standard Tournaments]]',
	mania = 'Mania[[Category:osu!mania Tournaments]]',
	['mania 4k'] = 'Mania (4 Keys)[[Category:osu!mania Tournaments]][[Category:osu!mania (4 Keys) Tournaments]]',
	['mania 7k'] = 'Mania (7 Keys)[[Category:osu!mania Tournaments]][[Category:osu!mania (7 Keys) Tournaments]]',
	taiko = 'Taiko[[Category:osu!taiko Tournaments]]',
	catch = 'Catch[[Category:osu!catch Tournaments]]',
	mixed  = 'Various Modes[[Category:Tournaments with Multiple game modes]]',
	default = '[[Category:Unknown Mode Tournaments]]',
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args
	_league = league

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted

	return league:createInfobox()
end

---@return WidgetInjector
function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Number of teams', content = {_args.team_number}},
		Cell{name = 'Number of players', content = {_args.player_number}},
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game Version', content = {
					Game.name{game = _args.game}
				}
			},
			Cell{name = 'Game Mode', content = {
					CustomLeague._getGameMode()
				}
			},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.game = Game.name{game = args.game}
	return lpdbData
end

---@param args table
---@return table
function CustomLeague._getGameMode()
	if String.isEmpty(_args.mode) then
		return nil
	end

	local mode = _MODES[string.lower(_args.mode or '')] or _MODES['default']
	return mode
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_publishertier', args.publisherpremier)
	Variables.varDefine('tournament_game', Game.name{game = args.game})
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.publisherpremier)
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

return CustomLeague
