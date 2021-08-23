---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Team/Custom
--

local Team = require('Module:Infobox/Team')
local Earnings = require('Module:Earnings')
local Variables = require('Module:Variables')

local RocketLeagueTeam = {}

function RocketLeagueTeam.run(frame)
    local team = Team(frame)
    team.addCustomCells = RocketLeagueTeam.addCustomCells
    team.calculateEarnings = RocketLeagueTeam.calculateEarnings
    return team:createInfobox(frame)
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
