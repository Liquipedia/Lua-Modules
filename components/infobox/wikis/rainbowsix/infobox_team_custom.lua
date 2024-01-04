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

---@class RainbowsixInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	-- Automatic achievements
	team.args.achievements = Achievements.team{
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	return team:createInfobox()
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

---@param args table
function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

return CustomTeam
