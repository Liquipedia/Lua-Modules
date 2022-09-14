---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/League/Hidden
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--this "infobox" has no display and only stores into LPDB, sets wiki vars and categories

local AllowedServers = require('Module:Server')
local Autopatch = require('Module:Automated Patch')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Json = require('Module:Json')
local LeagueIcon = require('Module:LeagueIcon')
local Links = require('Module:Links')
local Locale = require('Module:Locale')
local Localisation = require('Module:Localisation')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')

local HiddenInfoboxLeague = {}

local _args
local _pagename = mw.title.getCurrentTitle().text

local _TODAY = os.date('%Y-%m-%d', os.time())

local _GAME_WOL = 'wol'
local _GAME_HOTS = 'hots'
local _GAME_LOTV = 'lotv'
local _GAME_MOD = 'mod'

local _GAMES = {
	[_GAME_WOL] = {'Wings of Liberty', 'WoL'},
	[_GAME_HOTS] = {'Heart of the Swarm', 'HotS'},
	[_GAME_LOTV] = {'Legacy of the Void', 'LotV'},
	[_GAME_MOD] = {'mod', 'mod'}
}

function HiddenInfoboxLeague.run(args)
	_args = args

	HiddenInfoboxLeague._definePageVariables()

	local display = ''

	if HiddenInfoboxLeague._shouldStore() then
		HiddenInfoboxLeague._setLpdbData()
		display = HiddenInfoboxLeague._getCategories()
	else
		Variables.varDefine('disable_LPDB_storage', 'true')
	end

	return display
end

function HiddenInfoboxLeague._shouldStore()
	return Namespace.isMain() and
		_args.disable_lpdb ~= 'true' and
		_args.disable_storage ~= 'true' and
		Variables.varDefault('disable_LPDB_storage', 'false') ~= 'true'
end

function HiddenInfoboxLeague._getCategories()
	local categories = {
		'Tournaments',
	}

	if not String.isEmpty(_args.team_number) then
		table.insert(categories, 'Team Tournaments')
	end

	local touranmentType = tostring(_args.type):lower()
	if touranmentType == 'offline' then
		table.insert(categories, 'Offline Tournaments')
	elseif touranmentType == 'online' then
		table.insert(categories, 'Online Tournaments')
	else
		table.insert(categories, 'Unknown Type Tournaments')
	end

	if String.isNotEmpty(_args.server) then
		local server = _args.server
		server = string.gsub(server, '%s?/%s?=', '/')
		local servers = mw.text.split(server, '/')
		for _, item in ipairs(servers or {}) do
			local value = AllowedServers[item] or 'Server Unknown'
			--we only want the category, not the display
			value = string.gsub(value, '%]%]$', '')
			value = string.gsub(value, '.+Category:', '')
			table.insert(categories, value)
		end
	end

	table.insert(categories, HiddenInfoboxLeague.getTierCategories())

	table.insert(categories, HiddenInfoboxLeague._getCountryCategories())

	table.insert(categories, HiddenInfoboxLeague._getGameVersionCategory())

	if categories ~= {} then
		return '[[Category:' .. table.concat(categories, ']] [[Category:') .. ']]'
	end

	return ''
end

function HiddenInfoboxLeague._getCountryCategories()
	if String.isEmpty(_args.country) then
		return nil
	end
	local countryCategories = {}

	local index = 1
	local current = _args.country

	while not String.isEmpty(current) do
		local nationality = Localisation.getLocalisation({displayNoError = true}, current)

		if String.isEmpty(nationality) then
			table.insert(countryCategories, 'Unrecognised Country')
		else
			table.insert(countryCategories, nationality .. ' Tournaments')
		end

		index = index + 1
		current = _args['country' .. index]
	end

	return table.concat(countryCategories, ']] [[Category:')
end

function HiddenInfoboxLeague.getTierCategories()
	local tierCategories = {}

	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or _args.tiertype or ''

	local tierText = Tier.text.tiers[tier]
	if String.isNotEmpty(tier) and tierText == nil then
		table.insert(tierCategories, 'Pages with invalid Tier')
	end
	tierText = tierText or tier
	table.insert(tierCategories, tierText .. ' Tournaments')
	if _args.team_number or _args.team1 then
		table.insert(tierCategories, tierText .. ' Team Tournaments')
	end

	if String.isNotEmpty(tierType) and Tier.text.types[string.lower(tierType)] == nil then
		table.insert(tierCategories, 'Pages with invalid Tiertype')
	end

	if tierCategories == {} then
		return nil
	end

	return table.concat(tierCategories, ']] [[Category:')
end

function HiddenInfoboxLeague._definePageVariables()
	--set a var that tells other templates that a hidden infobox is used
	Variables.varDefine('hidden_infobox', 'true')

	local name = _args.name or _pagename
	Variables.varDefine('tournament_name', name)
	Variables.varDefine('tournament_shortname', _args.shortname or _args.abbreviation)
	Variables.varDefine('tournament_tickername', _args.tickername or name)

	local icon, iconDark = HiddenInfoboxLeague._getIcon()
	Variables.varDefine('tournament_icon', icon)
	Variables.varDefine('tournament_icondark', iconDark)
	Variables.varDefine('tournament_series', mw.ext.TeamLiquidIntegration.resolve_redirect(_args.series or ''))

	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or _args.tiertype or ''
	Variables.varDefine('tournament_liquipediatier', tier)
	Variables.varDefine('tournament_liquipediatiertype', tierType)

	Variables.varDefine('tournament_type', _args.type)
	Variables.varDefine('tournament_status', _args.status)

	Variables.varDefine('tournament_region', _args.region)
	Variables.varDefine('tournament_country', _args.country)
	Variables.varDefine('tournament_location', _args.location or _args.city)
	Variables.varDefine('tournament_location2', _args.location2 or _args.city2)
	Variables.varDefine('tournament_venue', _args.venue)

	Variables.varDefine('tournament_game', (_GAMES[string.lower(_args.game or '')] or {})[1] or _GAMES[_GAME_WOL][1])

	-- If no parent is available, set pagename instead to ease querying
	local parent = _args.parent or mw.title.getCurrentTitle().prefixedText
	parent = string.gsub(parent, ' ', '_')
	Variables.varDefine('tournament_parent', parent)
	Variables.varDefine('tournament_parentname', _args.parentname)
	Variables.varDefine('tournament_subpage', _args.subpage)

	local sdate = HiddenInfoboxLeague._cleanDate(_args.sdate) or HiddenInfoboxLeague._cleanDate(_args.date)
	local edate = HiddenInfoboxLeague._cleanDate(_args.edate) or HiddenInfoboxLeague._cleanDate(_args.date)
	Variables.varDefine('tournament_startdate', sdate)
	Variables.varDefine('tournament_enddate', edate)

	--Legacy vars
	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_tiertype', tierType)
	Variables.varDefine('tournament_ticker_name', _args.tickername or name)
	Variables.varDefine('tournament_abbreviation', _args.abbreviation or '')

	--SC2 specific vars
	Variables.varDefine('tournament_mode', _args.mode or '1v1')
	Variables.varDefine('headtohead', _args.headtohead or 'true')
	Variables.varDefine('featured', _args.featured or 'false')
	--series number
	local seriesNumber = _args.number or ''
	local seriesNumberLength = string.len(seriesNumber)
	if seriesNumberLength > 0 then
		seriesNumber = string.rep('0', 5 - seriesNumberLength) .. seriesNumber
	end
	Variables.varDefine('tournament_series_number', seriesNumber)
	--check if tournament is finished
	local finished = _args.finished
	local queryDate = Variables.varDefault('tournament_enddate', '2999-99-99')
	if finished ~= 'true' and os.date('%Y-%m-%d') >= queryDate then
		local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
				.. 'AND [[participant::!Definitions]] AND [[placement::1]]',
			query = 'date',
			order = 'date asc',
			limit = 1
		})
		if data ~= nil and data[1] ~= nil then
			finished = 'true'
		end
	end
	Variables.varDefine('tournament_finished', finished or 'false')
	--month and day
	local monthAndDay = string.match(edate or '', '%d%d-%d%d') or ''
	Variables.varDefine('Month_Day', monthAndDay)
	--breakdown vars
	local playerNumber = HiddenInfoboxLeague._playerRaceBreakDown()
	if playerNumber == 0 then
		playerNumber = HiddenInfoboxLeague._playerBreakDownEvent()
	end
	Variables.varDefine('tournament_playerNumber', playerNumber)
	--check if team event
	if _args.team_number or String.isNotEmpty(_args.team1) then
		Variables.varDefine('is_team_tournament', 1)
	end
	--prize pool
	Variables.varDefine('tournament_prizepoolusd', HiddenInfoboxLeague._getPrizePool())
	--patches
	local patch, epatch = HiddenInfoboxLeague._getPatch()
	Variables.varDefine('patch', patch)
	Variables.varDefine('epatch', epatch)

	--maps
	Variables.varDefine('tournament_maps', HiddenInfoboxLeague._getMaps())
end

function HiddenInfoboxLeague._getPrizePool()
	if String.isEmpty(_args.prizepool) and
		String.isEmpty(_args.prizepoolusd) then
		return 0
	end

	local localCurrency = _args.localcurrency
	local prizePoolUSD = _args.prizepoolusd
	local prizePool = _args.prizepool

	if localCurrency == 'text' then
		return 0
	else
		if prizePoolUSD then
			prizePoolUSD = HiddenInfoboxLeague._cleanPrizeValue(prizePoolUSD)
		end
		if prizePoolUSD then
			return prizePoolUSD
		end

		prizePool = HiddenInfoboxLeague._cleanPrizeValue(prizePool)

		if localCurrency then
			local exchangeDate = Variables.varDefault('tournament_enddate', _TODAY)
			prizePoolUSD = HiddenInfoboxLeague._currencyConversion(prizePool, localCurrency:upper(), exchangeDate)
			if not prizePoolUSD then
				error('Invalid local currency "' .. localCurrency .. '"')
			end
			return prizePoolUSD
		end
		return prizePool or 0
	end
end

function HiddenInfoboxLeague._cleanPrizeValue(value)
	if String.isEmpty(value) then
		return nil
	end

	--remove non numbers (leave dots)
	value = value:gsub('[^%d%.]', '')
	return tonumber(value)
end

function HiddenInfoboxLeague._currencyConversion(localPrize, currency, exchangeDate)
	local usdPrize
	local currencyRate = Currency.getExchangeRate{
		currency = currency,
		date = exchangeDate,
		setVariables = true,
	}
	if currencyRate then
		usdPrize = currencyRate * localPrize
	end

	return usdPrize
end

function HiddenInfoboxLeague._getPatch()
	local game = string.lower(_args.game or '')
	local patch = _args.patch or ''
	local shouldUseAutoPatch = _args.autopatch or ''
	local epatch = _args.epatch or ''
	local sdate = Variables.varDefault('tournament_startdate', _TODAY)
	local edate = Variables.varDefault('tournament_enddate', _TODAY)

	if String.isNotEmpty(game) then
		if (shouldUseAutoPatch == 'false' or game ~= 'lotv') and epatch == '' then
			epatch = patch
		end
		if patch == '' and game == _GAME_LOTV and shouldUseAutoPatch ~= 'false' then
			patch = 'Patch ' .. (Autopatch._main({sdate}) or '')
		end
		if epatch == '' and game == 'lotv' and shouldUseAutoPatch ~= 'false' then
			epatch = 'Patch ' .. (Autopatch._main({edate}) or '')
		end

		return patch, epatch
	end
	return '', ''
end

function HiddenInfoboxLeague._playerRaceBreakDown()
	local playerNumber = tonumber(_args.player_number or 0) or 0
	local zergNumber = tonumber(_args.zerg_number or 0) or 0
	local terranNumbner = tonumber(_args.terran_number or 0) or 0
	local protossNumber = tonumber(_args.protoss_number or 0) or 0
	local randomNumber = tonumber(_args.random_number or 0) or 0
	if playerNumber == 0 then
		playerNumber = zergNumber + terranNumbner + protossNumber + randomNumber
	end

	Variables.varDefine('nbnotableP', protossNumber)
	Variables.varDefine('nbnotableT', terranNumbner)
	Variables.varDefine('nbnotableZ', zergNumber)
	Variables.varDefine('nbnotableR', randomNumber)

	return playerNumber
end

function HiddenInfoboxLeague._playerBreakDownEvent()
	local codeS = tonumber(_args.code_s_number or 0) or 0
	local codeA = tonumber(_args.code_a_number or 0) or 0
	local premier = tonumber(_args.premier_number or 0) or 0
	local challenger = tonumber(_args.challenger_number or 0) or 0
	return codeS + codeA + premier + challenger
end

function HiddenInfoboxLeague._setLpdbData()
	local links = Links.transform(_args)

	local lpdbData = {
		name = _args.name or _pagename,
		tickername = _args.tickername or _args.name or _pagename,
		shortname = _args.shortname or _args.abbreviation,
		banner = _args.image,
		bannerdark = _args.imagedark or _args.imagedarkmode,
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		series = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.series or ''),
		game = string.lower(_args.game or ''),
		patch = Variables.varDefault('patch', ''),
		endpatch = Variables.varDefaultMulti('epatch', 'patch', ''),
		type = _args.type,
		organizers = mw.ext.LiquipediaDB.lpdb_create_json(
			HiddenInfoboxLeague._getNamedTableofAllArgsForBase('organizer')
		),
		startdate = Variables.varDefaultMulti('tournament_startdate', 'tournament_enddate', '1970-01-01'),
		enddate = Variables.varDefault('tournament_enddate', '1970-01-01'),
		sortdate = Variables.varDefault('tournament_enddate', '1970-01-01'),
		location = mw.text.decode(Locale.formatLocation({city = _args.city or _args.location, country = _args.country})),
		location2 = mw.text.decode(Locale.formatLocation({city = _args.city2 or _args.location2, country = _args.country2})),
		venue = _args.venue,
		prizepool = Variables.varDefault('tournament_prizepoolusd', 0),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		status = _args.status
			or Variables.varDefault('cancelled tournament', '') == 'true' and 'cancelled'
			or Variables.varDefault('tournament_finished', '') == 'true' and 'finished' or nil,
		format = _args.format,
		sponsors = mw.ext.LiquipediaDB.lpdb_create_json(
			HiddenInfoboxLeague._getNamedTableofAllArgsForBase('sponsor')
		),
		links = mw.ext.LiquipediaDB.lpdb_create_json(
			Links.makeFullLinksForTableItems(links or {})
		),
		maps = Variables.varDefault('tournament_maps'),
		participantsnumber = Variables.varDefault('tournament_playerNumber', _args.team_number or 0),
	}

	mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. lpdbData.name, lpdbData)
end

function HiddenInfoboxLeague._getMaps()
	local mapArgs
	local prefix
	if String.isNotEmpty(_args.map1) then
		mapArgs = _league:getAllArgsForBase(_args, 'map')
		prefix = 'map'
	elseif String.isNotEmpty(_args['2map1']) then
		mapArgs = _league:getAllArgsForBase(_args, '2map')
		prefix = '2map'
	elseif String.isNotEmpty(_args['3map1']) then
		mapArgs = _league:getAllArgsForBase(_args, '3map')
		prefix = '3map'
	end

	if not mapArgs then
		return ''
	end

	return Json.stringify(Table.map(mapArgs, function(mapIndex, map)
		map = mw.text.split(map, '|')
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(map[1]),
			displayname = _args[prefix .. mapIndex .. 'display'] or map[#map],
		}
	end))
end

function HiddenInfoboxLeague._getIcon()
	local icon = _args.icon
	local iconDark = _args.icondark or _args.icondarkmode
	if String.isEmpty(iconDark) then
		iconDark = icon
	end

	if String.isNotEmpty(icon) then
		return icon, iconDark
	end

	local series = _args.series
	if String.isEmpty(series) then
		return '', ''
	end

	local iconSmallTemplate = Template.safeExpand(
		mw.getCurrentFrame(),
		'LeagueIconSmall/' .. series:lower(),
		{ date = Variables.varDefault('tournament_enddate') }
	)
	return LeagueIcon.getIconFromTemplate({
		icon = icon,
		iconDark = iconDark,
		stringOfExpandedTemplate = iconSmallTemplate
	})
end

function HiddenInfoboxLeague._cleanDate(date)
	if HiddenInfoboxLeague._isUnknownDate(date) then
		return nil
	end

	date = date:gsub('-??', '-01')
	date = date:gsub('-XX', '-01')
	return date
end

function HiddenInfoboxLeague._isUnknownDate(date)
	return date == nil or string.lower(date) == 'tba' or string.lower(date) == 'tbd'
end

function HiddenInfoboxLeague._getNamedTableofAllArgsForBase(base)
	local basedArgs = HiddenInfoboxLeague._getAllArgsForBase(base)
	local namedArgs = {}
	for key, item in pairs(basedArgs) do
		namedArgs[base .. key] = item
	end
	return namedArgs
end

function HiddenInfoboxLeague._getAllArgsForBase(base, options)
	local foundArgs = {}
	if String.isEmpty(_args[base]) and String.isEmpty(_args[base .. '1']) then
		return foundArgs
	end

	options = options or {}
	local makeLink = Logic.readBool(options.makeLink)

	local baseArg = _args[base] or _args[base .. '1']
	if makeLink then
		local link = _args[base .. 'link'] or _args[base .. '1link'] or baseArg
		baseArg = '[[' .. link
			.. '|' .. baseArg .. ']]'
	end

	table.insert(foundArgs, baseArg)
	local index = 2

	while not String.isEmpty(_args[base .. index]) do
		local indexedbase = _args[base .. index]
		if makeLink then
			indexedbase = '[[' .. (_args[base .. index .. 'link'] or indexedbase)
				.. '|' .. indexedbase .. ']]'
		end
		table.insert(foundArgs, indexedbase)
		index = index + 1
	end

	return foundArgs
end

function HiddenInfoboxLeague._getGameVersionCategory()
	local game = string.lower(_args.game or '')
	local beta = _args.beta or ''

	if _GAMES[game] ~= nil then
		return (beta ~= '' and 'Beta ' or '') .. _GAMES[game][2] .. ' Competitions'
	elseif game ~= _GAME_MOD then
		return (beta ~= '' and 'Beta ' or '') .. ' Competitions'
	end

	return nil
end

return Class.export(HiddenInfoboxLeague)
