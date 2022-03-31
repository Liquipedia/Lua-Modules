---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Class = require('Module:Class')
local String = require('Module:String')
local Template = require('Module:Template')

local CustomTeam = Class.new()

local _team

-- TODO: Image rescaling

function CustomTeam.run(frame)
	local team = Team(frame)

	-- Override links to allow one param to set multiple links
	team.args.datdota = team.args.teamid
	team.args.dotabuff = team.args.teamid

	-- Automatic achievements
	team.args.achievements = Template.expandTemplate(frame, 'Team achievements')

	-- Automatic org people
	team.args.coach = Template.expandTemplate(frame, 'Coach of')
	team.args.director = Template.expandTemplate(frame, 'Director of')
	team.args.manager = Template.expandTemplate(frame, 'Manager of')
	team.args.captain = Template.expandTemplate(frame, 'Captain of')

	_team = team
	team.createBottomContent = CustomTeam.createBottomContent
	team.addToLpdb = CustomTeam.addToLpdb
	return team:createInfobox(frame)
end

function CustomTeam:createBottomContent()
--[[
	TODO:
	Leaving this out for now, will be a follow-up PR,
	as both the templates needs to be removed from team pages plus the templates also requires some div changes

	if not _team.args.disbanded then
		return Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing matches of',
			{team = _team.name or _team.pagename}
		) .. Template.expandTemplate(
			mw.getCurrentFrame(),
			'Upcoming and ongoing tournaments of',
			{team = _team.name or _team.pagename}
		)
	end
--]]
end

function CustomTeam:addToLpdb(lpdbData, args)
	if not String.isEmpty(_team.args.teamcardimage) then
		lpdbData.logo = 'File:' .. _team.args.teamcardimage
	elseif not String.isEmpty(_team.args.image) then
		lpdbData.logo = 'File:' .. _team.args.image
	end

	-- TODO: Investigate - Legacy Infobox store the raw input.
	-- Needs be investigated if it should use the output of Template:Region (via #var:region) instead
	-- lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

return CustomTeam
