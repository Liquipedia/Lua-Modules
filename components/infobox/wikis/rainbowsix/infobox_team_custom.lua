---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})
local Achievements = Lua.import('Module:Infobox/Extension/Achievements', {requireDevIfEnabled = true})

local ACHIEVEMENTS_BASE_CONDITIONS = {
	'[[liquipediatiertype::!Showmatch]]',
	'[[liquipediatiertype::!Qualifier]]',
	'([[liquipediatier::1]] OR [[liquipediatier::2]])',
	'[[placement::1]]',
}

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)
	-- Automatic achievements
	team.args.achievements = Achievements.team{
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}
	team.addToLpdb = CustomTeam.addToLpdb
	team.defineCustomPageVariables = CustomTeam.defineCustomPageVariables
	return team:createInfobox()
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

return CustomTeam
