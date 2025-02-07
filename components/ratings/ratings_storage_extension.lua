---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Storage/Extension
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local OpponentLibraries = require('Module:OpponentLibraries')
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
	-- Calculate Progression Points
	local progressionDates = {}
	progressionLimit = progressionLimit or 1
	local nextProgression = Date.parseIsoDate(date)
	table.insert(progressionDates, os.date('%F', os.time(nextProgression)) --[[@as string]])
	for _ = 1, progressionLimit do
		nextProgression.day = nextProgression.day - PROGRESSION_STEP_DAYS
		table.insert(progressionDates, os.date('%F', os.time(nextProgression)) --[[@as string]])
	end

	-- Get the ratings and progression
	local teams = mw.ext.Dota2Ranking.get(progressionDates[#progressionDates], date)

	-- Add additional data to the teams
	return Array.map(teams, function(team)
		local teamInfo = RatingsStorageExtension._getTeamInfo(team.name)
		local teamProgressionParsed = Array.map(team.progression, function(progression)
			return {
				date = progression.date,
				rating = RatingsStorageExtension._normalizeRating(progression.rating),
				rank = progression.rank,
			}
		end)
		local progression = Array.map(progressionDates, function(progressionDate)
			return Array.find(teamProgressionParsed, function(progression)
				return progression.date == progressionDate
			end) or {
				date = progressionDate,
			}
		end)

		if not progression[1].rank then
			error('Badly formated data')
		end
		local isNew = not progression[2].rank
		---@type RatingsEntry
		local newTeam = {
			name = team.name,
			rank = team.rank,
			rating = RatingsStorageExtension._normalizeRating(team.rating),
			region = teamInfo.region,
			opponent = Opponent.resolve(Opponent.readOpponentArgs({type = Opponent.team, team.name}), date),
			change = not isNew and progression[2].rank - progression[1].rank or nil,
			streak = team.streak,
			progression = progression,
		}
		return newTeam
	end)
end

--- Normalize a rating
---@param rating number
---@return number
function RatingsStorageExtension._normalizeRating(rating)
	return math.floor((rating * 1000) + 0.5)
end

--- Get team information from Team Template and Team Page
---@param teamName string
---@return {region: string?}
function RatingsStorageExtension._getTeamInfo(teamName)
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
