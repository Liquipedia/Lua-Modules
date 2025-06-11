---
-- @Liquipedia
-- page=Module:Ratings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local RatingsStorageLpdb = require('Module:Ratings/Storage/Lpdb')

local RatingsDisplay = {}

---@class RatingsEntryOld
---@field matches integer
---@field name string
---@field rating number
---@field region string
---@field streak integer
---@field shortName string
---@field progression table[]

---@class RatingsDisplayInterface
---@field build fun(teamRankings: RatingsEntryOld[]):string

local LIMIT_HISTORIC_ENTRIES = 24 -- How many historic entries are fetched

--- Entry point for the ratings display in graph display mode
---@param frame Frame
---@return string
function RatingsDisplay.graph(frame)
	local Display = require('Module:Ratings/Display/Graph')
	return RatingsDisplay.make(frame, Display)
end

--- Entry point for the ratings display in table list display mode
---@param frame Frame
---@return string
function RatingsDisplay.list(frame)
	local Display = require('Module:Ratings/Display/List')
	return RatingsDisplay.make(frame, Display)
end

---@param frame Frame
---@param displayClass RatingsDisplayInterface
---@return string
function RatingsDisplay.make(frame, displayClass)
	local args = Arguments.getArgs(frame)

	local teamRankings = RatingsDisplay._getTeamRankings(args.id, LIMIT_HISTORIC_ENTRIES)

	return displayClass.build(teamRankings)
end

---@param id string
---@param progressionLimit integer
---@return RatingsEntryOld[]
function RatingsDisplay._getTeamRankings(id, progressionLimit)
	local teams = RatingsStorageLpdb.getRankings(id, progressionLimit)

	Array.forEach(teams, function(team)
		local teamInfo = RatingsDisplay._getTeamInfo(team.name)

		team.region = teamInfo.region
		team.shortName = teamInfo.shortName
	end)

	return teams
end

--- Get team information from Team Template and Team Page
---@param teamName string
---@return {region: string?, shortName: string}
function RatingsDisplay._getTeamInfo(teamName)
	local teamInfo = RatingsDisplay._fetchTeamInfo(teamName)

	return {
		region = teamInfo.region or '???',
		shortName = mw.ext.TeamTemplate.teamexists(teamInfo.template or '')
			and mw.ext.TeamTemplate.raw(teamInfo.template).shortname or teamName
	}
end

--- Fetch team information from Team Page
---@param name string
---@return {template: string?, region: string?}
function RatingsDisplay._fetchTeamInfo(name)
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

return RatingsDisplay
