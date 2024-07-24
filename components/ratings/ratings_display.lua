---
-- @Liquipedia
-- wiki=commons
-- page=Module:Ratings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local RatingsStorageLpdb = require('Module:Ratings/Storage/Lpdb')

--- Liquipedia Ratings (LPR) Display
local RatingsDisplay = {}

-- Settings
local LIMIT_HISTORIC_ENTRIES = 24 -- How many historic entries is fetched

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
---@param displayClass {build: fun(playerRankings: table[]):string}
---@return unknown
function RatingsDisplay.make(frame, displayClass)
	local args = Arguments.getArgs(frame)

	local teamRankings = RatingsDisplay._getTeamRankings(args.id, LIMIT_HISTORIC_ENTRIES)

	return displayClass.build(teamRankings)
end

---@param id string
---@param progressionLimit integer
---@return table[]
function RatingsDisplay._getTeamRankings(id, progressionLimit)
	local teams = RatingsStorageLpdb.getRankings(id, progressionLimit)

	teams = RatingsDisplay._enrichTeamInformation(teams)

	return teams
end

---@param teams table[]
---@return table[]
function RatingsDisplay._enrichTeamInformation(teams)
	-- Update team information from Team Tempalte and Team Page
	Array.forEach(teams, function(team)
		local teamInfo = RatingsDisplay._getTeamInfo(team.name)

		team.region = teamInfo.region or '???'
		team.shortName = mw.ext.TeamTemplate.teamexists(teamInfo.template or '')
				and mw.ext.TeamTemplate.raw(teamInfo.template).shortname or team.name
	end)

	return teams
end

---@param name string
---@return {template: string?, region: string?}
function RatingsDisplay._getTeamInfo(name)
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
