---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local RoleOf = require('Module:RoleOf')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Team = Lua.import('Module:Infobox/Team', {requireDevIfEnabled = true})
local Region = Lua.import('Module:Region', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local REGION_REMAPPINGS = {
	['south america'] = 'latin america',
	['asia-pacific'] = 'pacific',
	['asia'] = 'pacific',
	['taiwan'] = 'pacific',
	['southeast asia'] = 'pacific',
}

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	_args = _team.args

	-- Automatic org people
	team.args.coach = RoleOf.get{role = 'Coach'}
	team.args.manager = RoleOf.get{role = 'Manager'}
	team.args.captain = RoleOf.get{role = 'Captain'}

	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories
	team.createRegion = CustomTeam.createRegion

	return team:createInfobox()
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name}
	) .. Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing tournaments of',
		{team = _team.name}
	)
end

function CustomInjector:addCustomCells(widgets)
	local args = _args
	table.insert(widgets, Cell{
		name = 'Abbreviation',
		content = {args.abbreviation}
	})

	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.region = Variables.varDefault('region', '')

	if String.isNotEmpty(args.league) then
		lpdbData.extradata.competesin = string.upper(args.league)
	end

	lpdbData.coach = Variables.varDefault('coachid') or args.coach or args.coaches
	lpdbData.manager = Variables.varDefault('managerid') or args.manager

	return lpdbData
end

function CustomTeam:getWikiCategories(args)
	local categories = {}

	if String.isNotEmpty(args.league) then
		local division = string.upper(args.league)
		table.insert(categories, division .. ' Teams')
	end

	return categories
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
