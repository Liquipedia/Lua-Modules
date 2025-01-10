---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tournament
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lpdb = require('Module:Lpdb')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Utils')

local Tournaments = {}

---@enum TournamentPhase
local TOURNAMENT_PHASE = {
	UPCOMING = 'UPCOMING',
	ONGOING = 'ONGOING',
	FINISHED = 'FINISHED',
}

---@class StandardTournament
---@field displayName string
---@field fullName string
---@field pageName string
---@field startDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?
---@field endDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?
---@field liquipediaTier string
---@field liquipediaTierType string
---@field region string
---@field featured boolean
---@field status string?
---@field phase TournamentPhase
---@field icon string?
---@field iconDark string?
---@field abbreviation string?
---@field series string?

---@param conditions ConditionTree?
---@param filterTournament fun(tournament: StandardTournament): boolean
---@return StandardTournament[]
function Tournaments.getAllTournaments(conditions, filterTournament)
	local tournaments = {}
	Lpdb.executeMassQuery(
		'tournament',
		{
			conditions = conditions and conditions:toString() or nil,
			order = 'sortdate desc',
			limit = 1000,
		},
		function(record)
			local tournament = Tournaments.tournamentFromRecord(record,	Tournaments.makeFeaturedFunction())
			if not filterTournament or filterTournament(tournament) then
				table.insert(tournaments, tournament)
			end
		end
	)
	return tournaments
end

---@param record tournament
---@param recordIsFeatured function
---@return StandardTournament
function Tournaments.tournamentFromRecord(record, recordIsFeatured)
	local startDate = Tournaments.parseDateRecord(record.startdate)
	local endDate = Tournaments.parseDateRecord(record.sortdate or record.enddate)

	local tournament = {
		displayName = Logic.emptyOr(record.tickername, record.name) or record.pagename:gsub('_', ' '),
		fullName = record.name,
		pageName = record.pagename,
		startDate = startDate,
		endDate = endDate,
		liquipediaTier = Tier.toIdentifier(record.liquipediatier),
		liquipediaTierType = Tier.toIdentifier(record.liquipediatiertype),
		region = record.region,
		status = record.status,
		featured = recordIsFeatured(record),
		icon = record.icon,
		iconDark = record.icondark,
		abbreviation = record.abbreviation,
		series = record.series,
	}

	tournament.phase = Tournaments.calculatePhase(tournament)

	return tournament
end

---@param tournament StandardTournament
---@return TournamentPhase
function Tournaments.calculatePhase(tournament)
	if tournament.status == 'finished' then
		return TOURNAMENT_PHASE.FINISHED
	end
	if not tournament.startDate then
		return TOURNAMENT_PHASE.UPCOMING
	end
	if DateExt.getCurrentTimestamp() < tournament.startDate.timestamp then
		return TOURNAMENT_PHASE.UPCOMING
	end
	if not tournament.endDate.timestamp then
		return TOURNAMENT_PHASE.ONGOING
	end
	if DateExt.getCurrentTimestamp() < tournament.endDate.timestamp then
		return TOURNAMENT_PHASE.ONGOING
	end
	return TOURNAMENT_PHASE.FINISHED
end

--- This function parses fuzzy dates into a structured format.
---@param dateRecord string # date in the format of `YYYY-MM-DD`, with `-MM-DD` optional.
---@return {year: integer, month: integer?, day: integer?, timestamp: integer?}?
function Tournaments.parseDateRecord(dateRecord)
	if not dateRecord then
		return nil
	end
	if dateRecord == DateExt.defaultDate then
		return nil
	end
	local year, month, day = dateRecord:match('^(%d%d%d%d)%-?(%d?%d?)%-?(%d?%d?)')
	year, month, day = tonumber(year), tonumber(month), tonumber(day)

	if not year then
		return
	end

	return {year = year, month = month, day = day, timestamp = DateExt.readTimestampOrNil(dateRecord)}
end

--- This function returns a function that can be used to determine if a tournament should be featured.
---@return fun(record: tournament): boolean
function Tournaments.makeFeaturedFunction()
	local curatedData = Lua.requireIfExists('Module:TournamentsList/CuratedData', {loadData = true})
	if not curatedData then
		return function() return false end
	end

	---@param record tournament
	---@return boolean
	local function recordIsCurated(record)
		if Table.includes(curatedData.exclude, record.pagename) then
			return false
		end
		if Table.includes(curatedData.include, record.pagename) then
			return true
		end
		if Table.includes({1, 2}, record.liquipediaTier) then
			return true
		end

		if Logic.isEmpty(record.liquipediaTierType) then
			return false
		end

		local function parentData(page, maxDepth)
			if maxDepth == 0 then
				return nil
			end
			local parentPage = mw.title.new(record.pagename).basePageTitle
			return mw.ext.LiquipediaDB.lpdb('tournament', {
				conditions = '[[pagename::' .. parentPage .. ']]',
				limit = 1,
			})[1] or parentData(parentPage, maxDepth - 1)
		end
		local parentTournament = parentData(record.pagename, 2)

		if not parentTournament then
			return false
		end
		return recordIsCurated(parentTournament)
	end

	return recordIsCurated
end

return Tournaments
