---
-- @Liquipedia
-- wiki=commons
-- page=Module:MetadataGenerator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AnOrA = require('Module:A or an')
local Class = require('Module:Class')
local Date = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier/Utils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Currency = Lua.import('Module:Currency')

local MetadataGenerator = {}

local TIME_FUTURE = 1
local TIME_ONGOING = 0
local TIME_PAST = -1

local TYPES_TO_DISPLAY = {'qualifier', 'showmatch'}

function MetadataGenerator.tournament(args)
	local output

	local name = not String.isEmpty(args.name) and (args.name):gsub('&nbsp;', ' ') or mw.title.getCurrentTitle().text

	local tournamentType = args.type
	local locality = Flags.getLocalisation(args.country)

	local organizers = {
		args['organizer-name'] or args.organizer,
		args['organizer2-name'] or args.organizer2,
		args['organizer3-name'] or args.organizer3,
	}

	---@type integer|string|nil
	---@type string?
	local tier, tierType = Tier.toName(args.liquipediatier, args.liquipediatiertype)
	tier = tier or 'Unknown Tier'
	if not tierType or not Table.includes(TYPES_TO_DISPLAY, Tier.toIdentifier(args.liquipediatiertype)) then
		tierType = 'tournament'
	end

	local publisher
	if args.publisherdescription then
		publisher = Variables.varDefault(args.publisherdescription, '')
	end
	local date, tense = MetadataGenerator._getDate(args.sdate or args.date, args.edate or args.date)

	local teams = args.team_number
	local players = args.player_number

	local game = Game.abbreviation({game = args.game, useDefault = true})

	local prizepoolusd = args.prizepoolusd and ('$' .. args.prizepoolusd .. ' USD') or nil
	local prizepool = prizepoolusd or (args.prizepool and args.localcurrency and
		Currency.display(args.localcurrency, args.prizepool, {formatValue = true, useHtmlStyling = false})
	)
	local charity = args.charity == 'true'
	local dateVerb = (tense == TIME_PAST and 'took place ')
		or (tense == TIME_FUTURE and 'will take place ')
		or 'takes place '

	local dateVerbPublisher =
		(tense == TIME_PAST and ' which took place ') or
		(tense == TIME_FUTURE and ' which will take place ') or
		' taking place '

	output = String.interpolate('${name} is ${a}${type}${locality}${game}${charity}${tierType}${organizer}', {
		name = name,
		a = AnOrA._main{
			tournamentType or locality or game or (charity and 'charity' or nil) or tierType,
			origStr = 'false' -- Ew (but has to be like this)
		},
		type = tournamentType and (tournamentType:lower() .. ' ') or '',
		locality = locality and (locality .. ' ') or '',
		game = game and (game .. ' ') or '',
		charity = charity and 'charity ' or '',
		tierType = tierType,
		organizer = organizers[1] and (' organized by ' .. organizers[1]) or ''
	})

	if organizers[2] then
		output = output .. (organizers[3] and ', ' or ' and ') ..
			organizers[2] .. (organizers[3] and (', and ' .. organizers[3]) or '') .. '. '
	else
		output = output .. '. '
	end

	output = output .. String.interpolate('This ${tier}${tierType} ', {
		tier = tierType ~= tier and (tier .. ' ') or '',
		tierType = tierType
	})
	if not String.isEmpty(publisher) then
		output = output .. String.interpolate('is a ${publisher}${tense}', {
			publisher = publisher,
			tense = ((date and dateVerbPublisher) or ((teams or players or prizepool) and ' featuring '))
		})
	elseif date then
		output = output .. dateVerb
	elseif teams or players or prizepool then
		output = output .. 'features '
	end

	if date then
		output = output .. date .. ((teams or players or prizepool) and ' featuring ' or '')
	end

	if teams or players then
		output = output .. ((teams and (teams .. ' teams')) or
			(players and (players .. ' players'))) ..
			(prizepool and ' ' or '')
	end
	if prizepool then
		output = output .. String.interpolate('${competing}a total ${charity}prize pool of ${prizepool}', {
			competing = (teams or players) and 'competing over ' or '',
			charity = charity and 'charity ' or '',
			prizepool = prizepool
		})
	end

	if not (date or teams or players or prizepool) then
		output = output .. 'is yet to take place'
	end

	output = output .. '.'

	return output
end

function MetadataGenerator._getDate(startDate, endDate)
	if not startDate or not endDate then
		return
	end

	local dateStringToStruct = function (dateString)
		local year, month, day = dateString:match('(%d%d%d%d)-?([%d%?]?[%d%?]?)-?([%d%?][%d%?]?)$')
		if not year then return {} end
		return {
			year = year,
			month = month,
			day = day,
			yearExact = tonumber(year) and true,
			monthExact = tonumber(month) and true,
			dayExact = tonumber(day) and true,
			timestamp = Date.readTimestamp(dateString:gsub('%?%?', '01'))
		}
	end

	local currentTimestamp = os.time()
	local startTime = dateStringToStruct(startDate)
	local endTime = dateStringToStruct(endDate)

	if not startTime.yearExact or not endTime.yearExact or not startTime.monthExact then
		return
	end

	local relativeTime = MetadataGenerator._getTimeRelativity(currentTimestamp, startTime, endTime)

	local sFormat, eFormat = MetadataGenerator._getDateFormat(startTime, endTime)

	local prefix
	if startTime.timestamp == endTime.timestamp and endTime.dayExact then
		prefix = 'on'
		sFormat = '%b %d %Y'
		eFormat = ''
	elseif startTime.timestamp == endTime.timestamp and endTime.monthExact then
		prefix = 'in'
		sFormat = '%b %Y'
		eFormat = ''
	elseif not endTime.monthExact then
		if relativeTime == TIME_FUTURE then
			prefix = 'starting'
		else
			prefix = 'started'
		end
		eFormat = ''
	else
		prefix = 'from'
	end

	local displayDate
	displayDate = prefix .. ' ' .. os.date('!' .. sFormat, startTime.timestamp)
	if String.isNotEmpty(eFormat) then
		displayDate = displayDate .. ' to ' .. os.date('!' .. eFormat, endTime.timestamp)
	end

	return displayDate, relativeTime
end

function MetadataGenerator._getTimeRelativity(timeNow, startTime, endTime)
	if timeNow < startTime.timestamp then
		return TIME_FUTURE
	elseif timeNow < endTime.timestamp then
		return TIME_ONGOING
	elseif timeNow > endTime.timestamp then
		return TIME_PAST
	end
end

function MetadataGenerator._getDateFormat(startTime, endTime)
	local formatStart, formatEnd
	if startTime.dayExact and startTime.year == endTime.year then
		formatStart = '%b %d'
	elseif startTime.dayExact then
		formatStart = '%b %d %Y'
	elseif startTime.year == endTime.year then
		formatStart = '%b'
	else
		formatStart = '%b %Y'
	end

	if endTime.dayExact and startTime.month == endTime.month then
		formatEnd = '%d %Y'
	elseif endTime.dayExact then
		formatEnd = '%b %d %Y'
	else
		formatEnd = '%b %Y'
	end

	return formatStart, formatEnd
end

return Class.export(MetadataGenerator)
