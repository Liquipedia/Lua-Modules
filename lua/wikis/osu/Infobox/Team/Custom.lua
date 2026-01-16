---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local PlacementStats = Lua.import('Module:InfoboxPlacementStats')

local Team = Lua.import('Module:Infobox/Team')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class OsuInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return Widget
function CustomTeam:createBottomContent()
	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		PlacementStats.run{
			participant = self.pagename,
			tiers = {'1', '2', '3', '4', '5'},
		},
		not self.args.disbanded and UpcomingTournaments.team{name = self.teamTemplate.templatename} or nil
	)}
end

return CustomTeam
