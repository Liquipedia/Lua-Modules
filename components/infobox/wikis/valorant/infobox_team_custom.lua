---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Team = require('Module:Infobox/Team')
local Earnings = require('Module:Earnings')
local Variables = require('Module:Variables')
local String = require('Module:String')
local Template = require('Module:Template')

local TeamRanking = require('Module:TeamRanking')

local CustomTeam = {}

local _team

function CustomTeam.run(frame)
    local team = Team(frame)
	_team = team
    team.addCustomCells = CustomTeam.addCustomCells
	team.addToLpdb = CustomTeam.addToLpdb
    team.calculateEarnings = CustomTeam.calculateEarnings
    return team:createInfobox(frame)
end

function CustomTeam:createBottomContent()
	return Template.expandTemplate(
		mw.getCurrentFrame(),
		'Upcoming and ongoing matches of',
		{team = _team.name or _team.pagename}
	)
end

function CustomTeam.addCustomCells(team, infobox, args)
    Variables.varDefine('rating', args.rating)
    local teamName = args.rankingname or team.pagename or team.name
    local vctRanking = TeamRanking.get({ranking = 'VCT_2021_Ranking', team = teamName})

    infobox :cell('[[Portal:Rating|LPRating]]', args.rating or 'Not enough data')
            :cell('[[VALORANT_Champions_Tour/2021/Circuit_Points|VCT Points]]', vctRanking)
    return infobox

end

function CustomTeam.calculateEarnings(team, args)
    return Earnings.calculateForTeam({team = team.pagename or team.name})
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

return CustomTeam
