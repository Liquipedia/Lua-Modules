---
-- @Liquipedia
-- wiki=worldofwarcraft
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local REGION_REMAPPINGS = {
	['cis'] = 'europe',

	['south america'] = 'americas',
	['latin america'] = 'americas',
	['north america'] = 'americas',

	['asia'] = 'southeast asia',
	['oceania'] = 'southeast asia',
	['asia-pacific'] = 'southeast asia',
}

local Region = Lua.import('Module:Region', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})

---@class WorldofwarcraftnfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)

	return team:createInfobox()
end

---@param region string?
---@return {display: string?, region: string?}
function CustomTeam:createRegion(region)
	if Logic.isEmpty(region) then return {} end

	local regionData = Region.run{region = region} or {}

	local remappedRegion = REGION_REMAPPINGS[regionData.region:lower()]
	if remappedRegion then
		return self:createRegion(remappedRegion)
	end

	return regionData
end

return CustomTeam
