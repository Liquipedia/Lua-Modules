---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class StormgateInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

local CustomInjector = Class.new(Injector)

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

	if id == 'achievements' then
		local achievements, soloAchievements = Achievements.teamAndTeamSolo()
		widgets = {}
		if achievements then
			table.insert(widgets, Title{children = 'Achievements'})
			table.insert(widgets, Center{children = {achievements}})
		end

		if soloAchievements then
			table.insert(widgets, Title{children = 'Solo Achievements'})
			table.insert(widgets, Center{children = {soloAchievements}})
		end

		local raceBreakdown = RaceBreakdown.run(args)
		if raceBreakdown then
			Array.appendWith(widgets,
				Title{children = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {raceBreakdown.total}},
				Breakdown{children = raceBreakdown.display, classes = { 'infobox-center' }}
			)
		end

		return widgets
	end
	return widgets
end

---@param args table
---@return table
function CustomTeam:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.disbanded) then
		table.insert(categories, 'Disbanded Teams')
	end
	return categories
end

return CustomTeam
