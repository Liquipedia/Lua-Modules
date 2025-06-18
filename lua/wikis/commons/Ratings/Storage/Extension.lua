---
-- @Liquipedia
-- page=Module:Ratings/Storage/Extension
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Date = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local RatingsStorageExtension = {}

local PROGRESSION_STEP_DAYS = 7 -- How many days each progression step is

---@param date string
---@param teamLimit integer?
---@param progressionLimit integer?
---@return RatingsEntry[]
function RatingsStorageExtension.getRankings(date, teamLimit, progressionLimit)
	if not date then
		error('No date provided')
	end
	if date > Date.getContextualDateOrNow() then
		error('Cannot get rankings for future date')
	end

	local progressionDates = RatingsStorageExtension._calculateProgressionDates(date, progressionLimit)

	local teams = mw.ext.Dota2Ranking.get(progressionDates[#progressionDates], date)

	-- Endpoint doesn't support team limit (yet?), so we'll have to cut it short here
	teams = Array.sub(teams, 1, math.min(teamLimit or #teams))

	return Array.map(teams, FnUtil.curry(RatingsStorageExtension._createTeamEntry, progressionDates))
end

--- Takes a team record from the endpoint and creates a RatingsEntry
---@param progressionDates string[]
---@param team Dota2RankingRecord
---@return RatingsEntry
function RatingsStorageExtension._createTeamEntry(progressionDates, team)
	local endDate = progressionDates[1]
	local lpdbTeamInfo = RatingsStorageExtension._getTeamInfoFromLpdb(team.name)

	local teamProgressionParsed = Array.map(team.progression, function(progression)
		return RatingsStorageExtension._createProgressionRecord(progression.date, progression.rating, progression.rank)
	end)

	-- Add today's progression record to the start of the list
	local progressionToday = RatingsStorageExtension._createProgressionRecord(endDate, team.rating, team.rank)
	table.insert(teamProgressionParsed, 1, progressionToday)

	local function findProgressionForDate(date)
		return Array.find(teamProgressionParsed, function(progression)
			return progression.date == date
		end)
	end

	local progression = Array.map(progressionDates, function(progressionDate)
		return findProgressionForDate(progressionDate) or RatingsStorageExtension._createProgressionRecord(progressionDate)
	end)

	local hasRankLastInterval = progression[2].rank ~= nil
	---@type RatingsEntry
	local newTeam = {
		name = team.name,
		rank = team.rank,
		rating = RatingsStorageExtension._normalizeRating(team.rating),
		region = lpdbTeamInfo.region,
		opponent = Opponent.resolve(Opponent.readOpponentArgs({type = Opponent.team, team.name}), endDate),
		change = hasRankLastInterval and progression[2].rank - progression[1].rank or nil,
		streak = team.streak,
		progression = progression,
	}
	return newTeam
end

--- Calculate which dates to get progression for
---@param date string
---@param progressionLimit integer?
---@return string[]
function RatingsStorageExtension._calculateProgressionDates(date, progressionLimit)
	local progressionDates = {}
	local nextProgression = Date.parseIsoDate(date)
	table.insert(progressionDates, os.date('%F', os.time(nextProgression)) --[[@as string]])
	for _ = 1, progressionLimit or 1 do
		nextProgression.day = nextProgression.day - PROGRESSION_STEP_DAYS
		table.insert(progressionDates, os.date('%F', os.time(nextProgression)) --[[@as string]])
	end
	return progressionDates
end

---@param date string
---@param rating number?
---@param rank integer?
---@return {date: string, rating?: number, rank?: integer}
function RatingsStorageExtension._createProgressionRecord(date, rating, rank)
	return {
		date = date,
		rating = rating and RatingsStorageExtension._normalizeRating(rating) or nil,
		rank = rank,
	}
end

--- Normalize a rating
---@param rating number
---@return number
function RatingsStorageExtension._normalizeRating(rating)
	return math.floor((rating * 1000) + 0.5)
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
