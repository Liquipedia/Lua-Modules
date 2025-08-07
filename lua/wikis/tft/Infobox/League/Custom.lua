---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local VALID_PUBLISHERTIERS = {'sponsored'}

---@class TftLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local GAME_MODES = {
	solo = 'Solos',
	duo = 'Duos',
	squad = 'Squads',
}
local DEFAULT_MODE = GAME_MODES.solo
local RIOT_ICON = '[[File:Riot Games Tier Icon.png|x12px|link=Riot Games|Tournament supported by Riot Games]]'

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Teams', children = {args.team_number}},
			Cell{name = 'Players', children = {args.participants_number}}
		)
	elseif id == 'gamesettings' then
		Array.appendWith(widgets,
			Cell{name = 'Game', children = {Game.name{game = args.game}}},
			Cell{name = 'Patch', children = {self.caller:_createPatchCell(args)}},
			Cell{name = 'Game Mode', children = {args.mode}}
		)
	end

	return widgets
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	if self.data.publishertier then
		return ' ' .. RIOT_ICON
	end
	return ''
end

---@param args table
function CustomLeague:customParseArguments(args)
	-- Normalize Mode input
	args.mode = args.mode and GAME_MODES[string.lower(args.mode):gsub('s$', '')] or DEFAULT_MODE
	self.data.mode = string.lower(args.mode)

	local publisherTier = (args.publishertier or ''):lower()
	self.data.publishertier = Table.includes(VALID_PUBLISHERTIERS, publisherTier) and publisherTier
end

---@param args table
---@return string?
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

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {args.mode .. ' Mode Tournaments'}
end
return CustomLeague
