---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Variables = require('Module:Variables')
local String = require('Module:String')
local Template = require('Module:Template')
local Injector = require('Module:Infobox/Widget/Injector')
local TeamRanking = require('Module:TeamRanking')

local CustomTeam = {}

local CustomInjector = Class.new(Injector)

local _team

function CustomTeam.run(frame)
	local team = Team(frame)
	_team = team
	team.createWidgetInjector = CustomTeam.createWidgetInjector
	team.addToLpdb = CustomTeam.addToLpdb
	return team:createInfobox(frame)
end

function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name or _team.pagename}
	)
end

function CustomInjector:addCustomCells(widgets)
	Variables.varDefine('rating', args.rating)
	local teamName = args.rankingname or team.pagename or team.name
	local vctRanking = TeamRanking.get({ranking = 'VCT_2021_Ranking', team = teamName})

	table.insert(widgets, Cell{name = '[[Portal:Rating|LPRating]]', content = {args.rating or 'Not enough data'}})
	table.insert(widgets, Cell{name = '[[VALORANT_Champions_Tour/2021/Circuit_Points|VCT Points]]', content = {vctRanking}})
	return widgets
end

function CustomTeam:addToLpdb(lpdbData, args)
	if not String.isEmpty(args.teamcardimage) then
		lpdbData.logo = 'File:' .. args.teamcardimage
	elseif not String.isEmpty(args.image) then
		lpdbData.logo = 'File:' .. args.image
	end

	lpdbData.region = Variables.varDefault('region', '')

	return lpdbData
end

function CustomTeam:createWidgetInjector()
	return CustomInjector()
end

return CustomTeam
