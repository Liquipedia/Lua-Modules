---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local CustomTeam = Class.new()

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	team.getWikiCategories = CustomTeam.getWikiCategories
	return team:createInfobox(frame)
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

function CustomTeam:addToLpdb(lpdbData, args)
	mw.logObject(args)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = args.image
	end

	lpdbData.region = Variables.varDefault('region', '')

	lpdbData.extradata = {
		lcs = String.isNotEmpty(args.lcs),
		lcsa = String.isNotEmpty(args.lcsa),
		am = String.isNotEmpty(args.am),
	}

	return lpdbData
end

function CustomTeam:getWikiCategories(args)
	local categories = {}

	if String.isNotEmpty(args.lcs) then
		table.insert(categories, 'LCS Teams')
	end
	if String.isNotEmpty(args.lcsa) then
		table.insert(categories, 'LCSA Teams')
	end
	if String.isNotEmpty(args.am) then
		table.insert(categories, 'AM Teams')
	end

	return categories
end

return CustomTeam
