local Team = require('Module:Infobox/Team')
local Earnings = require('Module:Earnings')
local Variables = require('Module:Variables')

local RocketLeagueTeam = {}

function RocketLeagueTeam.run(frame)
    Team.addCustomCells = RocketLeagueTeam.addCustomCells
    Team.calculateEarnings = RocketLeagueTeam.calculateEarnings
    return Team.run(frame)
end

function RocketLeagueTeam.addCustomCells(team, infobox, args)
    Variables.varDefine('rating', args.rating)
    infobox :cell('[[Portal:Rating|LPRating]]', args.rating or 'Not enough data')
    return infobox

end

function RocketLeagueTeam.calculateEarnings(team, args)
    return Earnings.calculateForTeam({team = team.pagename or team.name})
end

return RocketLeagueTeam
