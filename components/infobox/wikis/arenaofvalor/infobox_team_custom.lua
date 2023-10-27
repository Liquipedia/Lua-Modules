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
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})
local Region = Lua.import('Module:Region', {requireDevIfEnabled = true})

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

local CustomTeam = Class.new()

local _args

function CustomTeam.run(frame)
	local team = Team(frame)
	_args = team.args

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.createRegion = CustomTeam.createRegion

	return team:createInfobox()
end

function CustomTeam:createBottomContent()
	if not _args.disbanded then
		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing matches of'
		) .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of'
		) .. tostring(PlacementStats.run{tiers = {'1', '2', '3', '4', '5'}})
	end
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
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
