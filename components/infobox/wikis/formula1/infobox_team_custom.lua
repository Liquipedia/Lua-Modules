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
local TeamTemplates = require('Module:Team')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)
local Chronology = Widgets.Chronology

local _args
local _team

local STATISTICS = {
	{key = 'races', name = 'Races'},
	{key = 'wins', name = 'Wins'},
	{key = 'podiums', name = 'Podiums'},
	{key = 'poles', name = 'Pole positions'},
	{key = 'fastestlaps', name = 'Fastest Laps'},
	{key = 'points', name = 'Career Points'},
	{key = 'firstentry', name = 'First entry'},
	{key = 'firstwin', name = 'First win'},
	{key = 'lastentry', name = 'Last entry'},
}


---@param frame Frame
function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_args = _team.args

	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories
	return team:createInfobox()
end

---@return WidgetInjector
function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	Array.extendWith(widgets, CustomTeam._statisticsCells(_args))

	if _args.academy then
		local academyTeams = Array.map(_team:getAllArgsForBase(_args, 'academy'), function(team)
			return TeamTemplates.team(nil, team)
		end)
		Array.extendWith(widgets,
			{Title{name = 'Academy Team' .. (Table.size(academyTeams) > 1 and 's' or '')}},
			Array.map(academyTeams, function(academyTeam) return Center{content = {academyTeam}} end)
		)
	end

	if _args.previous or _args.next then
		Array.appendWith(
			widgets,
			Title{name = 'Chronology'},
			Chronology{content = {
				previous = _args.previous,
				previous2 = _args.previous2,
				next = _args.next,
				next2 = _args.next2,
			}}
		)
	end

	return widgets
end

---@param args table
---@return Widget[]
function CustomTeam._statisticsCells(args)
	if Array.all(STATISTICS, function(statsData) return args[statsData.key] == nil end) then
		return {}
	end
	local widgets = {Title{name = 'Team Statistics'}}
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
