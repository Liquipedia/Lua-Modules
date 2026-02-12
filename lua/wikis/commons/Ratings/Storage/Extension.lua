---
-- @Liquipedia
-- page=Module:Ratings/Storage/Extension
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Date = Lua.import('Module:Date/Ext')
local Opponent = Lua.import('Module:Opponent/Custom')
local Operator = Lua.import('Module:Operator')

local RatingsStorageExtension = {}

---@param teamLimit integer?
---@return RatingsEntry[]
function RatingsStorageExtension.getRankings(teamLimit)
	local rankings = mw.ext.Dota2Ranking.get()
	if not rankings then
		return {}
	end
	local teams = RatingsStorageExtension._mapDataToExpectedFormat(rankings)
	teams = Array.sortBy(teams, Operator.property('rank'))
	-- Endpoint doesn't support team limit (yet?), so we'll have to cut it short here
	teams = Array.sub(teams, 1, math.min(teamLimit or #teams))

	return Array.map(teams, RatingsStorageExtension._createTeamEntry)
end

---@param allRankings Dota2RankingRecord[]
---@return Dota2RankingTeam[]
function RatingsStorageExtension._mapDataToExpectedFormat(allRankings)
	local nonProvisionalRankings = Array.filter(allRankings, function(ranking)
		return not ranking.provisional
	end)
	local newestEntry = Array.maxBy(nonProvisionalRankings, function(rankedDate)
		return Date.readTimestamp(rankedDate.date)
	end)
	if not newestEntry then
		return {}
	end
	local dateOfNewestEntry = newestEntry.date

	local teamsData = {}

	for _, datedResults in ipairs(nonProvisionalRankings) do
		for _, datedEntry in ipairs(datedResults.entries) do
			if not teamsData[datedEntry.name] then
				teamsData[datedEntry.name] = {
					name = datedEntry.name,
					progression = {}
				}
			end
			local teamData = teamsData[datedEntry.name]

			if datedResults.date == dateOfNewestEntry then
				teamData.rank = datedEntry.rank
				teamData.rating = datedEntry.rating
			end

			table.insert(teamData.progression, {
				timestamp = Date.readTimestamp(datedResults.date),
				date = Date.toYmdInUtc(Date.parseIsoDate(datedResults.date)),
				rank = datedEntry.rank,
				rating = datedEntry.rating
			})
		end
	end

	local teamList = Array.map(Array.extractValues(teamsData), function(team)
		team.progression = Array.sortBy(team.progression, Operator.property('timestamp'), function (a, b)
			return a < b
		end)
		return team
	end)

	teamList = Array.filter(teamList, Operator.property('rank'))

	return teamList
end

---@alias Dota2RankingTeam {name: string, rank: integer, rating: number,
---progression: {date: string, rating: number, rank: integer}[]}

--- Takes a team record from the endpoint and creates a RatingsEntry
---@param team Dota2RankingTeam
---@return RatingsEntry
function RatingsStorageExtension._createTeamEntry(team)
	local lpdbTeamInfo = RatingsStorageExtension._getTeamInfoFromLpdb(team.name)

	local hasRankLastInterval = #team.progression >= 2

	---@type RatingsEntry
	return {
		name = team.name,
		rank = team.rank,
		rating = team.rating,
		region = lpdbTeamInfo.region,
		opponent = Opponent.resolve(Opponent.readOpponentArgs({ type = Opponent.team, team.name })),
		change = hasRankLastInterval and team.progression[#team.progression - 1].rank - team.rank or nil,
		progression = team.progression,
	}
end

--- Get team information from the Team Page via LPDB
---@param teamName string
---@return {region: string?}
function RatingsStorageExtension._getTeamInfoFromLpdb(teamName)
	local teamInfo = RatingsStorageExtension._fetchTeamInfo(teamName)

	return {
		region = teamInfo.region,
	}
end

--- Fetch team information from Team Page
---@param name string
---@return {region: string?}
function RatingsStorageExtension._fetchTeamInfo(name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'team',
		{
			query = 'region, template',
			limit = 1,
			conditions = '[[pagename::' .. string.gsub(name, ' ', '_') .. ']]'
		}
	)
	if not res[1] then
		mw.log('Warning: Cannot find teampage for ' .. name)
	end

	return res[1] or {}
end

return RatingsStorageExtension
