---
-- @Liquipedia
-- page=Module:Tournament
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

local Tournament = {}

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
---@field region string?
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
function Tournament.getAllTournaments(conditions, filterTournament)
	local tournaments = {}
	Lpdb.executeMassQuery(
		'tournament',
		{
			conditions = conditions and conditions:toString() or nil,
			order = 'sortdate desc',
			limit = 1000,
		},
		function(record)
			local tournament = Tournament.tournamentFromRecord(record)
			if not filterTournament or filterTournament(tournament) then
				table.insert(tournaments, tournament)
			end
		end
	)
	return tournaments
end

---@param pagename string
---@return StandardTournament?
function Tournament.getTournament(pagename)
	local record = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. pagename .. ']]',
		limit = 1,
	})[1]
	if not record then
		return nil
	end
	return Tournament.tournamentFromRecord(record)
end

local TournamentMT = {
	__index = function(tournament, property)
		if property == 'featured' then
			tournament[property] = Tournament.isFeatured(tournament)
		end
		if property == 'phase' then
			tournament[property] = Tournament.calculatePhase(tournament)
		end
		return rawget(tournament, property)
	end
}

---@param record tournament
---@return StandardTournament
function Tournament.tournamentFromRecord(record)
	local extradata = record.extradata or {}
	local startDate = Tournament.parseDateRecord(Logic.nilOr(extradata.startdatetext, record.startdate))
	local endDate = Tournament.parseDateRecord(Logic.nilOr(extradata.enddatetext, record.sortdate, record.enddate))

	local tournament = {
		displayName = Logic.emptyOr(record.tickername, record.name) or record.pagename:gsub('_', ' '),
		fullName = record.name,
		pageName = record.pagename,
		startDate = startDate,
		endDate = endDate,
		liquipediaTier = Tier.toIdentifier(record.liquipediatier),
		liquipediaTierType = Tier.toIdentifier(record.liquipediatiertype),
		region = (record.locations or {}).region1,
		status = record.status,
		icon = record.icon,
		iconDark = record.icondark,
		abbreviation = record.abbreviation,
		series = record.series,
		game = record.game
	}

	-- Some properties are derived from other properies and we can calculate them when accessed.
	setmetatable(tournament, TournamentMT)

	return tournament
end

---@param tournament StandardTournament
---@return TournamentPhase
function Tournament.calculatePhase(tournament)
	if tournament.status == 'finished' then
		return TOURNAMENT_PHASE.FINISHED
	end
	if not tournament.startDate then
		return TOURNAMENT_PHASE.UPCOMING
	end
	if DateExt.getCurrentTimestamp() < tournament.startDate.timestamp then
		return TOURNAMENT_PHASE.UPCOMING
	end
	if not tournament.endDate then
		return TOURNAMENT_PHASE.ONGOING
	end
	if DateExt.getCurrentTimestamp() < (tournament.endDate.timestamp + 24 * 60 * 60) then
		return TOURNAMENT_PHASE.ONGOING
	end
	return TOURNAMENT_PHASE.FINISHED
end

--- This function parses fuzzy dates into a structured format.
---@param dateRecord string? # date in the format of `YYYY-MM-DD`, with `-MM-DD` optional.
---@return {year: integer, month: integer?, day: integer?, timestamp: integer?}?
function Tournament.parseDateRecord(dateRecord)
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

	local dt = {year = year, month = month or 12, day = day or 31, hour = 0}
	local timestamp = os.time(dt)

	return {year = year, month = month, day = day, timestamp = timestamp}
end

--- Determines if a tournament is featured.
---@param record StandardTournament
---@return boolean
function Tournament.isFeatured(record)
	local curatedData = Lua.requireIfExists('Module:TournamentsList/CuratedData', {loadData = true})
	if not curatedData then
		return false
	end

	local pagename = record.pageName
	if Table.includes(curatedData.exclude, pagename) then
		return false
	end
	if Table.includes(curatedData.include, pagename) then
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

		local parentPage = table.concat(Array.sub(mw.text.split(page, '/'), 1, -2), '/')
		if Logic.isEmpty(parentPage) then
			return nil
		end

		return Tournament.getTournament(parentPage) or parentData(parentPage, maxDepth - 1)
	end
	local parentTournament = parentData(pagename, 2)

	if not parentTournament then
		return false
	end

	return parentTournament.featured
end

return Tournament
