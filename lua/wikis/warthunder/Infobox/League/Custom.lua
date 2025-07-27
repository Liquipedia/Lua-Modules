---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class WarThunderLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

-- Game Mode: Different Battle Mode each providing different pacing.
local MODES = {
	ab = 'Arcade',
	rb = 'Realistic',
	sb = 'Simulator',
	rbm = 'Realistic with Markers',
}
-- Vehicle: Type of units played in the event.
local VEHICLES = {
	aviation = 'Aviation',
	ground = 'Ground',
	naval = 'Naval',
	multiple = 'Multiple',
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
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local mode = MODES[string.lower(args.mode or '')] or 'Unknown'
		local vehicle = VEHICLES[string.lower(args.vehicle or '')] or 'Unknown'
		Array.appendWith(
			widgets,
			Cell{name = 'Mode', content = {mode}},
			Cell{name = 'Vehicle', content = {vehicle}}
		)
	end

	return widgets
end

return CustomLeague
