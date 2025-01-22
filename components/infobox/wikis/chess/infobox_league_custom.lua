---
-- @Liquipedia
-- wiki=chess
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class ChessLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local MODES = {
	classical = 'Classical',
	blitz = 'Blitz',
	rapid = 'Rapid',
	chess960 = 'Chess960',
	puzzle = 'Puzzle Rush',
	dice = 'Dice Chess',
	various = 'Multiple',
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

	if id == 'gamesettings' then
		return {Cell{name = 'Variant', content = {self.caller:_getGameMode()}},}
	end

	return widgets
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.mode = self:_getGameMode()
end


---@return string?
function CustomLeague:_getGameMode()
	return MODES[string.lower(self.args.mode or '')] or MODES['classical']
end

return CustomLeague
