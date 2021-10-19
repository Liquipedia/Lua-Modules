---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:TeamRanking
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---- This Module retrieves a team's ranking using the LPDB Objects created in https://liquipedia.net/rocketleague/Module:AutoPointsTable
---- This Module is created to show the rankings of teams and their RLCS Circuit Points in the team infobox

local TeamRanking = {}

local Class = require('Module:Class')

--- Entry point
-- returns a string representation which contains the current RLCS Points and rank of a team in terms of RLCS Points
-- @tparam argsType args
-- @treturn string|nil rankingString the string representation of the team's ranking or nil if the team doesn't have RLCS Points
function p.get(args)
	if not args['ranking'] then
		error('Please provide a ranking name!')
	end
	if not args['team'] then
		mw.log('No team name provided')
		return nil
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
	if not teamData or place == '-1' then
		return nil
	end

	local place = teamData.information
	local points = teamData.extradata.totalpoints
	return points..' (Rank #'..place..')'
end

--- arguments provided to this module's get function
-- @tfield string ranking the name of the ranking as stored in LPDB
-- @tfield string name the name of the team to get the ranking for
-- @table argsType

return Class.export(p)
