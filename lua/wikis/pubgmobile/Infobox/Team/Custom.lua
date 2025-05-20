---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PlacementStats = require('Module:InfoboxPlacementStats')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class PubgmobileInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return Widget
function CustomTeam:createBottomContent()
	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		not self.args.disbanded and UpcomingTournaments{name = self.name or self.pagename},
		PlacementStats.run{
			participant = self.pagename,
			tiers = {'1', '2', '3', '4', '5'},
		}
	)}
end

---@param args table
function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_catain', args.captain)
end

return CustomTeam
