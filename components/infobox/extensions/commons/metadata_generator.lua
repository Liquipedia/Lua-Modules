---
-- @Liquipedia
-- wiki=commons
-- page=Module:MetadataGenerator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')
local Date = require('Module:Date/Ext')
local Localisation = require('Module:Localisation')
local Games = mw.loadData('Module:Games')
local Variables = require('Module:Variables')
local StringUtils = require('Module:StringUtils')
local Class = require('Module:Class')
local AnOrA = require('Module:A or an')
local Tier = mw.loadData('Module:Tier')
local Table = mw.loadData('Module:Table')

local MetadataGenerator = {}

local TIME_FUTURE = 1
local TIME_ONGOING = 0
local TIME_PAST = -1

local TYPES_TO_DISPLAY = {'qualifier', 'showmatch', 'show match'}

function MetadataGenerator.tournament(args)
	local output

	local name = not String.isEmpty(args.name) and (args.name):gsub('&nbsp;', ' ') or mw.title.getCurrentTitle()

	local type = args.type
	local locality = Localisation.getLocalisation({displayNoError = true}, args.country)

	local organizers = {
		args['organizer-name'] or args.organizer,
		args['organizer2-name'] or args.organizer2,
		args['organizer3-name'] or args.organizer3,
	}

	---@type string?
	local tier = args.liquipediatier and MetadataGenerator.getTierText(args.liquipediatier) or nil

	if not tier then
		tier = 'Unknown Tier'
	end

	local tierType = 'tournament'
	if args.liquipediatiertype then
		local tierTypeLower = args.liquipediatiertype:lower()
		if Table.includes(TYPES_TO_DISPLAY, tierTypeLower) then
			tierType = tierTypeLower
		end
	end

	local publisher
	if args.publisherdescription then
		publisher = Variables.varDefault(args.publisherdescription, '')
	end
	local date, tense = MetadataGenerator.getDate(args.sdate or args.date, args.edate or args.date)

	local teams = args.team_number
	local players = args.player_number

	local game
	if type(Games.abbr) == 'function' and args.primarygame and String.isNotEmpty(args.game)
		and args.game == args.primarygame then

		game = Games.abbr[args.game]
	end

	local prizepoolusd = args.prizepoolusd and ('$' .. args.prizepoolusd .. ' USD') or nil
	local prizepool = prizepoolusd or (
		args.prizepool and args.localcurrency and (
			Variables.varDefault('localcurrencysymbol', '') .. args.prizepool ..
			Variables.varDefault('localcurrencysymbolafter', '') .. ' ' ..
			Variables.varDefault('localcurrencycode', '')
		)
	)
	local charity = args.charity == 'true'
	local dateVerb = (tense == TIME_PAST and 'took place ')
		or (tense == TIME_FUTURE and 'will take place ')
		or 'takes place '

	local dateVerbPublisher =
		(tense == TIME_PAST and ' which took place ') or
		(tense == TIME_FUTURE and ' which will take place ') or
		' taking place '

	output = StringUtils.interpolate('${name} is ${a}${type}${locality}${game}${charity}${tierType}${organizer}', {
		name = name,
		a = AnOrA._main(type or locality or game or (charity and 'charity' or nil) or tierType) .. ' ',
		type = type and (type:lower() .. ' ') or '',
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

	output = output .. StringUtils.interpolate('This ${tier}${tierType} ', {
		tier = tierType ~= tier and (tier .. ' ') or '',
		tierType = tierType
	})
	if not String.isEmpty(publisher) then
		output = output .. StringUtils.interpolate('is a ${publisher}${tense}', {
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
		output = output .. StringUtils.interpolate('${competing}a total ${charity}prize pool of ${prizepool}', {
			competing = (teams or players) and 'competing over ' or '',
			charity = charity and 'charity ' or '',
			prizepool = prizepool
		})
	end

	output = output .. '.'

	return output
end

function MetadataGenerator.getTierText(tierString)
	if not Tier.text.tiers then -- allow legacy tier modules
		return Tier.text[tierString]
	else -- default case, i.e. tier module with intended format
		return Tier.text.tiers[tierString:lower()]
	end
end

function MetadataGenerator.getDate(startDate, endDate)
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

	local relativeTime = MetadataGenerator.getTimeRelativity(currentTimestamp, startTime, endTime)

	local sFormat, eFormat = MetadataGenerator.getDateFormat(startTime, endTime)

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

function MetadataGenerator.getTimeRelativity(timeNow, startTime, endTime)
	if timeNow < startTime.timestamp then
		return TIME_FUTURE
	elseif timeNow < endTime.timestamp then
		return TIME_ONGOING
	elseif timeNow > endTime.timestamp then
		return TIME_PAST
	end
end

function MetadataGenerator.getDateFormat(startTime, endTime)
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
