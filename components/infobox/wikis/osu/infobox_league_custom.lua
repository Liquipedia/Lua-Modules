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

local MODES = {
	standard = {display = 'Standard', category = 'Osu!standard Tournaments'},
	mania = {display = 'Mania', category = 'Osu!mania Tournaments'},
	['mania 4k'] = {display = 'Mania (4 Keys)', category = 'Osu!mania (4 Keys) Tournaments'},
	['mania 7k'] = {display = 'Mania (7 Keys)', category = 'Osu!mania (7 Keys) Tournaments'},
	taiko = {display = 'Taiko', category = 'Osu!taiko Tournaments'},
	catch = {display = 'Catch', category = 'Osu!catch Tournaments'},
	mixed = {display = 'Various Modes', category = 'Tournaments with Multiple game modes'},
	default = {display = 'Unknown', category = 'Unknown Mode Tournaments'},
}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.getWikiCategories = CustomLeague.getWikiCategories

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
					CustomLeague._getGameMode().display
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

---@return table
function CustomLeague._getGameMode()
	if String.isEmpty(_args.mode) then
		return {}
	end

	return MODES[string.lower(_args.mode or '')] or MODES.default
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

---@param args table
---@return table
function CustomLeague:getWikiCategories(args)
	return {CustomLeague._getGameMode().category}
end

return CustomLeague
