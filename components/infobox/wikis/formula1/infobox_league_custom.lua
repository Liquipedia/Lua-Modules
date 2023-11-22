---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = League(frame)
	_args = league.args

	league.addToLpdb = CustomLeague.addToLpdb
	league.createWidgetInjector = CustomLeague.createWidgetInjector

	return league:createInfobox()
end

---@return WidgetInjector
function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.appendWith(widgets,
		Cell{name = 'Race Number', content = {_args.race}},
		Cell{name = 'Total Laps', content = {_args.laps}},
		Cell{name = 'Pole Position', content = {_args.pole}},
		Cell{name = 'Fastest Lap', content = {_args.fastestlap}},
		Cell{name = 'Number of Races', content = {_args.numberofraces}},
		Cell{name = 'Number of Drivers', content = {_args.driver_number}},
		Cell{name = 'Number of Teams', content = {_args.team_number}}
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.participantsnumber = args.driver_number or args.team_number
	return lpdbData
end

return CustomLeague
