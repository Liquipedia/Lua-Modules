---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
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
			Cell{name = 'Race Number', children = {args.race}},
			Cell{name = 'Total Laps', children = {args.laps}},
			Cell{name = 'Pole Position', children = {args.pole}},
			Cell{name = 'Fastest Lap', children = {args.fastestlap}},
			Cell{name = 'Number of Races', children = {args.numberofraces}},
			Cell{name = 'Number of Drivers', children = {args.driver_number}},
			Cell{name = 'Number of Teams', children = {args.team_number}},
			Cell{name = 'Engine', children = {args.engine}},
			Cell{name = 'Tyres', children = {args.tyres}},
			Cell{name = 'Chassis', children = {args.chassis}}
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
