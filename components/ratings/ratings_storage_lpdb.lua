---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Storage/Lpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local RatingsStorageLpdb = {}

-- static conditions for LPDB
local STATIC_CONDITIONS_LPR_SNAPSHOT = '[[namespace::4]] AND [[type::LPR_SNAPSHOT]]'

---@param id string
---@param teamLimit integer?
---@param progressionLimit integer?
---@return RatingsEntry[]
function RatingsStorageLpdb.getRankings(id, teamLimit, progressionLimit)
	local snapshot = RatingsStorageLpdb._getSnapshot(id)
	if not snapshot then
		error('Could not find a Rating with this ID')
	end

	-- Merge the ranking and team data tables
	-- Toss away teams that are lower ranked than what is interesting
	local teams = {}
	for rank, teamName in ipairs(snapshot.extradata.ranks) do
		local teamInfo = RatingsStorageLpdb._getTeamInfo(teamName)
		local team = snapshot.extradata.table[teamName] or {}
		team.opponent = Opponent.resolve(Opponent.readOpponentArgs({type = Opponent.team, teamName}))
		team.region = teamInfo.region

		table.insert(teams, team)
		if rank >= teamLimit then
			break
		end
	end

	teams = RatingsStorageLpdb._addProgressionData(teams, id, progressionLimit or 0)

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

	return teams
end

---@param timestamp integer
---@param rating number
---@return {date: string, rating: number?}
function RatingsStorageLpdb._createProgressionEntry(timestamp, rating)
	return {
		date = os.date('%Y-%m-%d', timestamp),
		rating = rating,
		-- TODO: Add rank!
	}
end

--- Get team information from Team Template and Team Page
---@param teamName string
---@return {region: string?}
function RatingsStorageLpdb._getTeamInfo(teamName)
	local teamInfo = RatingsStorageLpdb._fetchTeamInfo(teamName)

	return {
		region = teamInfo.region,
	}
end

--- Fetch team information from Team Page
---@param name string
---@return {region: string?}
function RatingsStorageLpdb._fetchTeamInfo(name)
	local res = mw.ext.LiquipediaDB.lpdb(
		'team',
		{
			query = 'region',
			limit = 1,
			conditions = '[[pagename::' .. string.gsub(name, ' ', '_') .. ']]'
		}
	)
	if not res[1] then
		mw.log('Warning: Cannot find teampage for ' .. name)
	end

	return res[1] or {}
end

return RatingsStorageLpdb
