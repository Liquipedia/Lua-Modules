local Team = require('Module:Infobox/Team')
local Earnings = require('Module:Earnings')
local Variables = require('Module:Variables')
local TeamMatches = require('Module:Matches/Team')

local TeamRanking = require('Module:TeamRanking')

local RocketLeagueTeam = {}

function RocketLeagueTeam.run(frame)
    local team = Team(frame)
    Team.addCustomCells = RocketLeagueTeam.addCustomCells
    Team.calculateEarnings = RocketLeagueTeam.calculateEarnings
    return team:createInfobox(frame)
end

function RocketLeagueTeam.addCustomCells(team, infobox, args)
    Variables.varDefine('rating', args.rating)
    local teamName = args.rankingname or team.pagename or team.name
    local rlcsRanking = TeamRanking.get({ranking = 'RLCS_X_Ranking', team = teamName})

    infobox :cell('[[Portal:Rating|LPRating]]', args.rating or 'Not enough data')
            --:cell('[[RankingTableRLCS|RLCS Points]]', rlcsRanking)
    return infobox

end

function RocketLeagueTeam.calculateEarnings(team, args)
    return Earnings.calculateForTeam({team = team.pagename or team.name})
end

return RocketLeagueTeam
