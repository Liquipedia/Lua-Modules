---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class OsuLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

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
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Number of teams', content = {args.team_number}},
			Cell{name = 'Number of players', content = {args.player_number}},
		}
	elseif id == 'gamesettings' then
		return {
			Cell{name = 'Game Version', content = {
					Game.name{game = args.game}
				}
			},
			Cell{name = 'Game Mode', content = {
					CustomLeague._getGameMode(args).display
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
function CustomLeague._getGameMode(args)
	if String.isEmpty(args.mode) then
		return {}
	end

	return MODES[string.lower(args.mode or '')] or MODES.default
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('tournament_game', Game.name{game = args.game})
end

---@param args table
---@return table
function CustomLeague:getWikiCategories(args)
	return {CustomLeague._getGameMode(args).category}
end

return CustomLeague
