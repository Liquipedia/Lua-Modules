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

---@class Formula1LeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

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
		return Array.appendWith(widgets,
			Cell{name = 'Race Number', content = {args.race}},
			Cell{name = 'Total Laps', content = {args.laps}},
			Cell{name = 'Pole Position', content = {args.pole}},
			Cell{name = 'Fastest Lap', content = {args.fastestlap}},
			Cell{name = 'Number of Races', content = {args.numberofraces}},
			Cell{name = 'Number of Drivers', content = {args.driver_number}},
			Cell{name = 'Number of Teams', content = {args.team_number}},
			Cell{name = 'Engine', content = {args.engine}},
			Cell{name = 'Tyres', content = {args.tyres}},
			Cell{name = 'Chassis', content = {args.chassis}}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = args.driver_number or args.team_number
	return lpdbData
end

return CustomLeague
