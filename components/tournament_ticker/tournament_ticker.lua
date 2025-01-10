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

local TournamentTicker = {}

---@class StandardTournament
---@field displayName string
---@field pageName string
---@field startDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?
---@field endDate {year: integer, month: integer?, day: integer?, timestamp: integer?}?
---@field liquipediaTier string
---@field liquipediaTierType string
---@field region string
---@field featured boolean
---@field status 'UPCOMING'|'ONGOING'|'FINISHED'

---@class TournamentStatus
---@field isTournamentInStatus fun(record: StandardTournament): boolean
---@field enum 'UPCOMING'|'ONGOING'|'FINISHED'

local TOURNAMENT_STATUS = {
	UPCOMING = 'UPCOMING',
	ONGOING = 'ONGOING',
	FINISHED = 'FINISHED',
}

---@type TournamentStatus
local STATUS_UPCOMING = {
	enum = TOURNAMENT_STATUS.UPCOMING,
	isTournamentInStatus = function(tournament)
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
	sort = function(tournament1, tournament2)
		if tournament1.startdate ~= tournament2.startdate then
			return tournament1.startdate > tournament2.startdate
		end
		return tournament1.sortdate > tournament2.sortdate
	end
}
---@type TournamentStatus
local STATUS_ONGOING = {
	enum = TOURNAMENT_STATUS.ONGOING,
	isTournamentInStatus = function(tournament)
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
	sort = function(tournament1, tournament2)
		if tournament1.sortdate ~= tournament2.sortdate then
			return tournament1.sortdate < tournament2.sortdate
		end
		return tournament1.startdate > tournament2.startdate
	end
}

---@type TournamentStatus
local STATUS_CONCLUDED = {
	enum = TOURNAMENT_STATUS.FINISHED,
	isTournamentInStatus = function(tournament)
		-- No known enddate, cannot have finished
		if tournament.endDate.timestamp == DateExt.defaultTimestamp then
			return false
		end
		-- Has ended
		if DateExt.getCurrentTimestamp() >= tournament.endDate.timestamp then
			return false
		end
		return true
	end,
	sort = function(tournament1, tournament2)
		if tournament1.sortdate ~= tournament2.sortdate then
			return tournament1.sortdate < tournament2.sortdate
		end
		return tournament1.startdate > tournament2.startdate
	end
}

function TournamentTicker.getTournamentsFromDB()
	local tournaments = {}
	Lpdb.executeMassQuery('tournament', {}, function (record)
		local tournament = TournamentTicker.tournamentFromRecord(
			record,
			TournamentTicker.makeFeaturedFunction(),
			{
				STATUS_UPCOMING,
				STATUS_ONGOING,
				STATUS_CONCLUDED,
			}
		)
		table.insert(tournaments, tournament)
		return tournament ~= nil
	end)
	return tournaments
end

---@param record tournament
---@param recordIsFeatured function
---@param statuses TournamentStatus[]
---@return StandardTournament?
function TournamentTicker.tournamentFromRecord(record, recordIsFeatured, statuses)
	local startDate = TournamentTicker.parseDateRecord(record.startdate)
	local endDate = TournamentTicker.parseDateRecord(record.sortdate or record.enddate)

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
	}

	local status = Array.filter(statuses, function(status)
		return status.isTournamentInStatus(tournament)
	end)[1]

	if not status then
		return nil
	end

	tournament.status = status.enum
	tournament.featured = recordIsFeatured(record)

	return tournament
end

--- This function parses fuzzy dates into a structured format.
---@param dateRecord string # date in the format of `YYYY-MM-DD`, with `-MM-DD` optional.
---@return {year: integer, month: integer?, day: integer?, timestamp: integer?}?
function TournamentTicker.parseDateRecord(dateRecord)
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

function TournamentTicker.makeFeaturedFunction()
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

return TournamentTicker
