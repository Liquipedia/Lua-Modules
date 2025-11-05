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
local Opponent = Lua.import('Module:Opponent/Custom')

local RatingsStorageExtension = {}

local PROGRESSION_STEP_DAYS = 7 -- How many days each progression step is

---@param teamLimit integer?
---@return RatingsEntry[]
function RatingsStorageExtension.getRankings(teamLimit)
	local rankings = mw.ext.Dota2Ranking.get()

	return Array.map(rankings, FnUtil.curry(RatingsStorageExtension._createTeamEntry, progressionDates))
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
		return findProgressionForDate(progressionDate) or
			RatingsStorageExtension._createProgressionRecord(progressionDate)
	end)

	local hasRankLastInterval = progression[2].rank ~= nil
	---@type RatingsEntry
	local newTeam = {
		name = team.name,
		rank = team.rank,
		rating = RatingsStorageExtension._normalizeRating(team.rating),
		region = lpdbTeamInfo.region,
		opponent = Opponent.resolve(Opponent.readOpponentArgs({ type = Opponent.team, team.name }), endDate),
		change = hasRankLastInterval and progression[2].rank - progression[1].rank or nil,
		progression = progression,
	}
	return newTeam
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
