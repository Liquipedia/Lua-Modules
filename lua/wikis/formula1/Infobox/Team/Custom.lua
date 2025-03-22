---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local TeamInline = Lua.import('Module:Widget/TeamDisplay/Inline/Standard')

---@class Formula1InfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)
local Chronology = Widgets.Chronology

local STATISTICS = {
	{key = 'races', name = 'Races'},
	{key = 'wins', name = 'Wins'},
	{key = 'podiums', name = 'Podiums'},
	{key = 'poles', name = 'Pole positions'},
	{key = 'fastestlaps', name = 'Fastest Laps'},
	{key = 'points', name = 'Career Points'},
	{key = 'firstentry', name = 'First entry'},
	{key = 'firstwin', name = 'First win'},
	{key = 'lastwin', name = 'Last win'},
	{key = 'lastentry', name = 'Last entry'},
}

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.extendWith(widgets, CustomTeam._statisticsCells(args))

		if args.academy then
			local academyTeams = Array.map(self.caller:getAllArgsForBase(args, 'academy'), function(team)
				return TeamInline{name = team}
			end)
			Array.extendWith(widgets,
				{Title{children = 'Academy Team' .. (Table.size(academyTeams) > 1 and 's' or '')}},
				Array.map(academyTeams, function(academyTeam) return Center{children = {academyTeam}} end)
			)
		end

		if args.previous or args.next then
			Array.appendWith(
				widgets,
				Title{children = 'Chronology'},
				Chronology{links = {
					previous = args.previous,
					previous2 = args.previous2,
					next = args.next,
					next2 = args.next2,
				}}
			)
		end
	end

	return widgets
end

---@param args table
---@return Widget[]
function CustomTeam._statisticsCells(args)
	if Array.all(STATISTICS, function(statsData) return args[statsData.key] == nil end) then
		return {}
	end
	local widgets = {Title{children = 'Team Statistics'}}
	Array.forEach(STATISTICS, function(statsData)
		table.insert(widgets, Cell{name = statsData.name, content = {args[statsData.key]}})
	end)
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.previous = args.previous
	lpdbData.extradata.previous2 = args.previous2
	lpdbData.extradata.next = args.next
	lpdbData.extradata.next2 = args.next2

	return lpdbData
end

return CustomTeam
