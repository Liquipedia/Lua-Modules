---
-- @Liquipedia
-- wiki=warthunder
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

-- Battle Mode: Different Battle Mode each providing different pacing.
local BATTLEMODE = {
	ab = 'Arcade',
	rb = 'Realistic',
	sb = 'Simulator',
	rbm = 'Realistic with Markers',
}

-- Vehicle: Type of units played in the event.
local VEHICLE = {
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
		-- Process battle mode - convert to lowercase for matching
		local battlemodeInput = string.lower(args.battlemode or '')
		local battlemodeValue = BATTLEMODE[battlemodeInput] or 'Unknown'

		-- Process vehicle type - convert to lowercase for matching
		local vehicleInput = string.lower(args.vehicle or '')
		local vehicleValue = VEHICLE[vehicleInput] or 'Unknown'

		Array.appendWith(
			widgets,
			Cell{name = 'Battle Mode', content = {battlemodeValue}},
			Cell{name = 'Vehicle', content = {vehicleValue}}
		)
	end

	return widgets
end

return CustomLeague
