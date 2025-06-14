---
-- @Liquipedia
-- page=Module:TeamRanking
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---- This Module retrieves a team's ranking using the LPDB Objects
---- created in https://liquipedia.net/rocketleague/Module:AutoPointsTable
---- This Module is created to show the rankings of teams and their RLCS Circuit Points in the team infobox

local TeamRanking = {}

local Class = require('Module:Class')

--- Entry point
-- returns a string representation which contains the current RLCS Points and rank of a team in terms of RLCS Points
--- @param args table
--- @return string|nil #rankingString team's ranking string or nil if team has no points
function TeamRanking.run(args)
	if not args['ranking'] then
		error('Please provide a ranking name')
	end
	if not args['team'] then
		error('Please provide a team name')
	end

	local rankingName = args['ranking']
	local teamName = string.lower(args['team'])
	local query = {
		limit = 1,
		conditions = '[[type::' .. rankingName .. ']] AND [[name::' .. teamName .. ']]',
		query = 'information, extradata',
		order = 'date desc',
	}
	local data = mw.ext.LiquipediaDB.lpdb('datapoint', query)
	local teamData = data[1]
	if not teamData then
		return nil
	end
	local place = teamData.information
	if place == '-1' then
		return nil
	end
	local points = teamData.extradata.totalpoints
	return points .. ' (Rank #' .. place .. ')'
end


return Class.export(TeamRanking, {exports = {'run'}})
