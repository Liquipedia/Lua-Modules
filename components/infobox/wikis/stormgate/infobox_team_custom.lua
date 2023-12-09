---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomTeam = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = Team(frame)
	_args = team.args

	team.createBottomContent = CustomTeam.createBottomContent
	team.getWikiCategories = CustomTeam.getWikiCategories
	team.addToLpdb = CustomTeam.addToLpdb
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'achievements' then
		local achievements, soloAchievements = Achievements.teamAndTeamSolo()
		widgets = {}
		if achievements then
			table.insert(widgets, Title{name = 'Achievements'})
			table.insert(widgets, Center{content = {achievements}})
		end

		if soloAchievements then
			table.insert(widgets, Title{name = 'Solo Achievements'})
			table.insert(widgets, Center{content = {soloAchievements}})
		end

		--need this ABOVE the history display and below the
		--achievements display, hence moved it here
		local raceBreakdown = RaceBreakdown.run(_args)
		if raceBreakdown then
			Array.appendWith(widgets,
				Title{name = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {raceBreakdown.total}},
				Breakdown{content = raceBreakdown.display, classes = { 'infobox-center' }}
			)
		end

		return widgets
	end
	return widgets
end

---@return WidgetInjector
function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

---@return Html?
function CustomTeam:createBottomContent()
	if Namespace.isMain() then
		return MatchTicker.participant{team = self.pagename}
	end
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = nil

	return lpdbData
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
