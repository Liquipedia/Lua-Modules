---
-- @Liquipedia
-- wiki=arenaofvalor
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local PlacementStats = require('Module:InfoboxPlacementStats')
local RoleOf = require('Module:RoleOf')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team')

---@class ArenaofvalorInfoboxTeam: InfoboxTeam
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

---@return string?
function CustomTeam:createBottomContent()
	if not self.args.disbanded then
		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of'
		) .. tostring(PlacementStats.run{tiers = {'1', '2', '3', '4', '5'}})
	end
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
