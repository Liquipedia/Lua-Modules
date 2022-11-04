---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

local CustomTeam = Class.new()

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.defineCustomPageVariables = CustomTeam.defineCustomPageVariables
	return team:createInfobox(frame)
end

function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name or _team.pagename}
	)
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

return CustomTeam
