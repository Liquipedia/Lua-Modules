---
-- @Liquipedia
-- page=Module:Ratings/Storage/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')

local RatingsStorageLpdb = {}

-- static conditions for LPDB
local STATIC_CONDITIONS_LPR_SNAPSHOT = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]]'

local LIMIT_TEAMS = 100 -- How many teams to do the calculations for

---@param id string
---@param progressionLimit integer
---@return table[]
function RatingsStorageLpdb.getRankings(id, progressionLimit)
	local snapshot = RatingsStorageLpdb._getSnapshot(id)
	if not snapshot then
		error('Could not find a Rating with this ID')
	end

	-- Merge the ranking and team data tables
	-- Toss away teams that are lower ranked than what is interesting
	local teams = {}
	for rank, teamName in ipairs(snapshot.extradata.ranks) do
		local team = snapshot.extradata.table[teamName] or {}
		team.name = teamName
		table.insert(teams, team)
		if rank >= LIMIT_TEAMS then
			break
		end
	end

	teams = RatingsStorageLpdb._addProgressionData(teams, id, progressionLimit)

	return teams
end

---@param name string
---@param offset integer?
---@return datapoint
function RatingsStorageLpdb._getSnapshot(name, offset)
	return mw.ext.LiquipediaDB.lpdb(
		'datapoint',
		{
			query = 'extradata, date',
			limit = 1,
			offset = offset,
			order = 'date DESC',
			conditions = STATIC_CONDITIONS_LPR_SNAPSHOT .. ' AND [[name::' .. name .. ']]'
		}
	)[1]
end

---@param teams table[]
---@param id string
---@param limit integer
---@return table[]
function RatingsStorageLpdb._addProgressionData(teams, id, limit)
	-- Build rating progression with snapshots
	for i = 0, limit do
		local snapshot = RatingsStorageLpdb._getSnapshot(id, i)
		if not snapshot then
			break
		end

		local snapshotTime = os.time(Date.parseIsoDate(snapshot.date))

		Array.forEach(teams, function(team)
			local rating = (snapshot.extradata.table[team.name] or {}).rating
			team.progression = team.progression or {}

			table.insert(team.progression, RatingsStorageLpdb._createProgressionEntry(snapshotTime, rating))
		end)
	end

	-- Put progression in the correct order (oldest to newest)
	Array.forEach(teams, function(team)
		team.progression = Array.reverse(team.progression)
	end)

	return teams
end

---@param timestamp integer
---@param rating number
---@return {date: string, rating: string}
function RatingsStorageLpdb._createProgressionEntry(timestamp, rating)
	return {
		date = os.date('%Y-%m-%d', timestamp),
		rating = rating and tostring(math.floor(rating + 0.5)) or '',
	}
end

return RatingsStorageLpdb
