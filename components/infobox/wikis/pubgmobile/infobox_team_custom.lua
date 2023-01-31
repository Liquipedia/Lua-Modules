---
-- @Liquipedia
-- wiki=pubgmobile
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PlacementSummary = require('Module:Placement summary')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local CustomTeam = Class.new()

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createBottomContent = CustomTeam.createBottomContent
	team.defineCustomPageVariables = CustomTeam.defineCustomPageVariables
	return team:createInfobox()
end

function CustomTeam:createBottomContent()
	local upcomingTable = ''
	if not _team.args.disbanded then
		upcomingTable = upcomingTable .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = _team.name or _team.pagename}
		)
	end
	return tostring(PlacementSummary.get_data({team = _team.pagename})) .. upcomingTable
end

function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

return CustomTeam
