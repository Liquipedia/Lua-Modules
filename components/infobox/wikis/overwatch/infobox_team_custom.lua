---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
--[[local Template = require('Module:Template')]]--

local CustomTeam = Class.new()

--[[local _team]]--

function CustomTeam.run(frame)
	local team = Team(frame)
	--[[_team = team]]--
	--[[team.createBottomContent = CustomTeam.createBottomContent]]--
	team.addToLpdb = CustomTeam.addToLpdb
	team.defineCustomPageVariables = CustomTeam.defineCustomPageVariables
	return team:createInfobox(frame)
end

--[[ TODO: Impliment after wiki transitions to Match2
function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name or _team.pagename}
	)
end
]]--

function CustomTeam:addToLpdb(lpdbData, args)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = 'File:' .. args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = 'File:' .. args.image
	end

	lpdbData.region = Variables.varDefault('region', '')

	lpdbData.extradata = {
		owl = String.isNotEmpty(args.owl),
	}

	return lpdbData
end

function CustomTeam:defineCustomPageVariables(args)
	Variables.varDefine('team_captain', args.captain)
end

function CustomTeam:getWikiCategories(args)
	local categories = {}

	if String.isNotEmpty(args.owl) then
		table.insert(categories, 'Overwatch League Teams')
	end

	return categories
end

return CustomTeam
