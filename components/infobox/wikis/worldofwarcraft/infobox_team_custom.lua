---
-- @Liquipedia
-- wiki=worldofwarcraft
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})
local Region = Lua.import('Module:Region', {requireDevIfEnabled = true})

local REGION_REMAPPINGS = {
	['cis'] = 'europe',

	['south america'] = 'americas',
	['latin america'] = 'americas',
	['north america'] = 'americas',

	['asia'] = 'southeast asia',
	['oceania'] = 'southeast asia',
	['asia-pacific'] = 'southeast asia',
}

local CustomTeam = Class.new()

function CustomTeam.run(frame)
	local team = Team(frame)

	team.createRegion = CustomTeam.createRegion

	return team:createInfobox()
end

function CustomTeam:createRegion(region)
	if String.isEmpty(region) then
		return
	end

	local regionData = Region.run({region = region})
	if Table.isEmpty(regionData) then
		return
	end

	local remappedRegion = REGION_REMAPPINGS[regionData.region:lower()]
	if remappedRegion then
		return CustomTeam:createRegion(remappedRegion)
	end

	Variables.varDefine('region', regionData.region)

	return regionData.display
end

return CustomTeam
