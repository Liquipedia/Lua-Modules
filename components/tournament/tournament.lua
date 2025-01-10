---
-- @Liquipedia
-- wiki=commons
-- page=Module:Tournament/Ticker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Lpdb = require('Module:Lpdb')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Utils')

local Tournaments = {}

---@class StandardTournament
---@field displayName string
---@field pageName string
---@field startDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?
---@field endDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?
---@field liquipediaTier string
---@field liquipediaTierType string
---@field region string
---@field featured boolean
---@field status string?
---@field phase 'UPCOMING'|'ONGOING'|'FINISHED'

---@class TournamentPhase
---@field isTournamentInPhase fun(record: StandardTournament): boolean
---@field enum 'UPCOMING'|'ONGOING'|'FINISHED'

local TOURNAMENT_PHASE = {
	UPCOMING = 'UPCOMING',
	ONGOING = 'ONGOING',
	FINISHED = 'FINISHED',
}

---@type TournamentPhase
local TOURNAMENT_PHASE_UPCOMING = {
	enum = TOURNAMENT_PHASE.UPCOMING,
	isTournamentInPhase = function(tournament)
		-- No known startdate, technically upcoming but rather unknown
		if tournament.startDate.timestamp == DateExt.defaultTimestamp then
			return false
		end
		-- Has started
		if DateExt.getCurrentTimestamp() >= tournament.startDate.timestamp then
			return false
		end
		return true
	end,
}
---@type TournamentPhase
local TOURNAMENT_PHASE_ONGOING = {
	enum = TOURNAMENT_PHASE.ONGOING,
	isTournamentInPhase = function(tournament)
		-- Has eneded
		if DateExt.getCurrentTimestamp() >= tournament.endDate.timestamp then
			return false
		end
		-- Has not started
		if DateExt.getCurrentTimestamp() < tournament.startDate.timestamp then
			return false
		end
		return true
	end,
}
---@type TournamentPhase
local TOURNAMENT_PHASE_CONCLUDED = {
	enum = TOURNAMENT_PHASE.FINISHED,
	isTournamentInPhase = function(tournament)
		-- No known enddate, cannot have finished
		if tournament.endDate.timestamp == DateExt.defaultTimestamp then
			return false
		end
		-- Has not ended
		if DateExt.getCurrentTimestamp() < tournament.endDate.timestamp then
			return false
		end
		return true
	end,
}

---@param conditions ConditionTree?
function Tournaments.getAllTournaments(conditions)
	local tournaments = {}
	Lpdb.executeMassQuery('tournament', {
		conditions = conditions and conditions:toString() or nil,
	}, function (record)
		local tournament = Tournaments.tournamentFromRecord(
			record,
			Tournaments.makeFeaturedFunction(),
			{
				TOURNAMENT_PHASE_UPCOMING,
				TOURNAMENT_PHASE_ONGOING,
				TOURNAMENT_PHASE_CONCLUDED,
			}
		)
		table.insert(tournaments, tournament)
	end)
	return tournaments
end

---@param record tournament
---@param recordIsFeatured function
---@param statuses TournamentPhase[]
---@return StandardTournament?
function Tournaments.tournamentFromRecord(record, recordIsFeatured, statuses)
	local startDate = Tournaments.parseDateRecord(record.startdate)
	local endDate = Tournaments.parseDateRecord(record.sortdate or record.enddate)

	local tournament = {
		displayName = Logic.emptyOr(record.tickername, record.name) or record.pagename:gsub('_', ' '),
		fullName = record.name,
		pageName = record.pageName,
		startDate = startDate,
		endDate = endDate,
		liquipediaTier = Tier.toIdentifier(record.liquipediatier),
		liquipediaTierType = record.liquipediatiertype,
		liquipediaTierType2 = record.extradata.liquipediatiertype2,
		region = record.region,
		status = record.status
	}

	local phase = Array.filter(statuses, function(status)
		return status.isTournamentInPhase(tournament)
	end)[1]

	if not phase then
		return nil
	end

	tournament.phase = phase.enum
	tournament.featured = recordIsFeatured(record)

	return tournament
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
