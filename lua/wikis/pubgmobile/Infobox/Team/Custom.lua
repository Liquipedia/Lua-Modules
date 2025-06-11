---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PlacementStats = require('Module:InfoboxPlacementStats')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team')

---@class PubgmobileInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@return string
function CustomTeam:createBottomContent()
	local upcomingTable = ''
	if not self.args.disbanded then
		upcomingTable = upcomingTable .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = self.name or self.pagename}
		)
	end
	return tostring(PlacementStats.run{
		participant = self.pagename,
		tiers = {'1', '2', '3', '4', '5'},
	}) .. upcomingTable
end

---@param args table
function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

return CustomTeam
