---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local RoleOf = require('Module:RoleOf')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Team = Lua.import('Module:Infobox/Team')

local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

local ACHIEVEMENTS_BASE_CONDITIONS = {
	'[[liquipediatiertype::!Showmatch]]',
	'[[liquipediatiertype::!Qualifier]]',
	'[[liquipediatiertype::!Charity]]',
	'[[liquipediatier::1]]',
	'[[placement::1]]',
}

---@class Dota2InfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	-- Override links to allow one param to set multiple links
	team.args.datdota = team.args.teamid
	team.args.dotabuff = team.args.teamid
	team.args.stratz = team.args.teamid

	-- Automatic achievements
	team.args.achievements = Achievements.team{
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.director = RoleOf.get{role = 'Director'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	return team:createInfobox()
end

---@return Widget?
function CustomTeam:createBottomContent()
	if not self.args.disbanded then
		return UpcomingTournaments{name = self.pagename}
	end
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.teamid = args.teamid

	return lpdbData
end

return CustomTeam
