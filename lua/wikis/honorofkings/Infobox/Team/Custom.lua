---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local PlacementStats = Lua.import('Module:InfoboxPlacementStats')
local RoleOf = Lua.import('Module:RoleOf')

local Region = Lua.import('Module:Region')
local Team = Lua.import('Module:Infobox/Team')
local UpcomingTournaments = Lua.import('Module:Infobox/Extension/UpcomingTournaments')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local REGION_REMAPPINGS = {
	['latin america'] = 'south america',

	['thailand'] = 'southeast asia',
	['vietnam'] = 'southeast asia',
	['indonesia'] = 'southeast asia',
	['philippines'] = 'southeast asia',
	['singapore'] = 'southeast asia',
	['malaysia'] = 'southeast asia',

	['bangladesh'] = 'south asia',
	['pakistan'] = 'south asia',

	['taiwan'] = 'asia',
	['asia-pacific'] = 'asia',
	['japan'] = 'asia',
}

---@class HonorofkingsInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	return team:createInfobox()
end

---@param region string?
---@return {display: string?, region: string?}
function CustomTeam:createRegion(region)
	if Logic.isEmpty(region) then return {} end

	local regionData = Region.run{region = region} or {}
	local remappedRegion = regionData.region and REGION_REMAPPINGS[(regionData.region or ''):lower()]

	return remappedRegion and self:createRegion(remappedRegion) or regionData
end

---@return Widget?
function CustomTeam:createBottomContent()
	if not self.args.disbanded then
		return HtmlWidgets.Fragment{children = {
			UpcomingTournaments.team(self.teamTemplate.templatename),
			PlacementStats.run{tiers = {'1', '2', '3', '4', '5'}}
		}}
	end
end

return CustomTeam
