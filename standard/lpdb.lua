---
-- @Liquipedia
-- wiki=commons
-- page=Module:Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lpdb = {}

-- Executes a mass query.
--[==[
Loops Lpdb queries to e.g.
- circumvent the maximum limit of 5000
- use additional filtering (e.g. because lpdb does not support it)
	and query so long until a certain amount of elements is found
	or additional limitations are reached

example:
	local foundMatchIds = {}
	local getMatchId = function(match)
		if #foundMatchIds < args.matchLimit then
			if HeadToHead._fitsAdditionalConditions(args, match) then
				table.insert(foundMatchIds, match.match2id)
			end
		else
			return false
		end
	end

	local queryParameters = {
		conditions = conditions,
		order = 'date ' .. args.order,
		limit = _LPDB_QUERY_LIMIT,
		query = 'pagename, winner, walkover, finished, date, dateexact, links, '
			.. 'bestof, vod, tournament, tickername, shortname, icon, icondark, '
			.. 'extradata, match2opponents, match2games, mode, match2id, match2bracketid',
	}
	Lpdb.executeMassQuery('match2', queryParameters, getMatchId)

	return foundMatchIds
]==]
function Lpdb.executeMassQuery(lpdbTable, queryParameters, callbackFunction, limit)
	queryParameters.offset = queryParameters.offset or 0
	queryParameters.limit = queryParameters.limit or 5000
	limit = limit or math.huge

	while queryParameters.offset < limit do
		queryParameters.limit = math.min(queryParameters.limit, limit - queryParameters.offset)

		local lpdbData = mw.ext.LiquipediaDB.lpdb(lpdbTable, queryParameters)
		for _, value in ipairs(lpdbData) do
			local success = callbackFunction(value)
			if success == false then
				return
			end
		end

		queryParameters.offset = queryParameters.offset + #lpdbData
		if #lpdbData < queryParameters.limit then
			return
		end
	end
end

return Lpdb
