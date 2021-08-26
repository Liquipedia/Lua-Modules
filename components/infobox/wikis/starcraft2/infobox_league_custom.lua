---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local Cell = require('Module:Infobox/Cell')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local Class = require('Module:Class')
local Autopatch = require('Module:Automated Patch')._main
local Tier = require('Module:Tier')
local Namespace = require('Module:Namespace')
local AllowedServers = require('Module:Server')
local RaceIcon = require('Module:RaceIcon')

local CustomLeague = Class.new()

local _ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
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
local _SICON = '[[File:Sicon.png|text-bottom|Code S|link=Code S]]'
local _AICON = '[[File:Aicon.png|text-bottom|Code A]]'
local _PICON = '[[File:PIcon.png|text-bottom|Premier League]]'
local _CICON = '[[File:CIcon.png|text-bottom|Challenger League]]'

function CustomLeague.run(frame)
	local league = League(frame)
	league.addCustomCells = CustomLeague.addCustomCells
	league.createTier = CustomLeague.createTier
	league.createPrizepool = CustomLeague.createPrizepool
	league.addCustomContent = CustomLeague.addCustomContent
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb

	league.getServer = CustomLeague.getServer
	league.getChronologyData = CustomLeague.getChronologyData
	league.shouldStore = CustomLeague.shouldStore

	return league:createInfobox(frame)
end

function CustomLeague:addCustomCells(infobox, args)
	infobox:cell('Game Version',
		CustomLeague._getGameVersion(string.lower(args.game or ''), args.patch or '', args))

	return infobox
end

function CustomLeague:createTier(args)
	local tierDisplay = CustomLeague:_createTierDisplay(args)
	local tierClass = ''
	if args.featured == 'true' then
		tierClass = 'sc2premier-highlighted'
	end
	local cell = Cell:new('Liquipedia Tier'):addClass(tierClass):content(tierDisplay)
	return cell
end

function CustomLeague:_createTierDisplay(args)
	local tier = args.liquipediatier or ''
	local tierType = args.liquipediatiertype or args.tiertype or ''
	if tier == '' then
		return nil
	end

	local tierText = Tier['text'][tier]
	local hasInvalidTier = tierText == nil
	tierText = tierText or tier

	local hasTierType = tierType ~= ''
	local hasInvalidTierType = false

	local output = '[[' .. tierText .. ' Tournaments|'

	if hasTierType then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil

		output = output .. tierType .. '&nbsp;(' .. tierText .. ')'
	else
		output = output .. tierText
	end

	output = output .. ']]' ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '')


	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_tiertype', tierType)
	return output
end

function CustomLeague:getChronologyData(args)
	local nxt, previous = CustomLeague._computeChronology(args)
	return {
		previous = previous,
		next = nxt,
		previous2 = args.previous2,
		next2 = args.next2,
		previous3 = args.previous3,
		next3 = args.next3,
	}
end

-- Automatically fill in next/previous for touranaments that are part of a series
function CustomLeague._computeChronology(args)
	-- Criteria for automatic chronology are
	-- - part of a series and numbered
	-- - the subpage name matches the number
	-- - prev or next are unspecified
	-- - and not suppressed via auto_chronology=false
	local title = mw.title.getCurrentTitle()
	local number = tonumber(title.subpageText or '')
	local automateChronology =
		(args.series or '') ~= ''
		and number ~= nil
		and tonumber(args.number or '') == number
		and title.subpageText ~= title.text
		and args.auto_chronology ~= 'false'
		and ((args.next or '') == '' or (args.previous or '') == '')

	if automateChronology then
		local previous = (args.previous or '') ~= '' and args.previous
		local next = (args.next or '') ~= '' and args.next
		local nextPage = (args.next or '') == '' and
			title.basePageTitle:subPageTitle(tostring(number + 1)).fullText
		local previousPage = (args.previous or '') == '' and
			title.basePageTitle:subPageTitle(tostring(number - 1)).fullText

		if not next and self:exists(nextPage) then
			next = nextPage .. '|#' .. tostring(number + 1)
		end

		if not previous and 1 < number and self:exists(previousPage) then
			previous = previousPage .. '|#' .. tostring(number - 1)
		end

		return next, previous
	else
		return args.next, args.previous
	end
end

function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		args.disable_smw ~= 'true' and
		args.disable_lpdb ~= 'true' and
		args.disable_storage ~= 'true' and
		Variables.varDefault('disable_SMW_storage', 'false') ~= 'true'
end

function CustomLeague:getServer(args)
	local server = args.server or ''
	server = string.gsub(server, '%s?/%s?=', '/')
	local servers = mw.text.split(server, '/')

	local output = ''
	for key, item in ipairs(servers or {}) do
		item = string.lower(item)
		if key ~= 1 then
			output = output .. ' / '
		end
		output = output .. (AllowedServers[item] or ('[[Category:Server Unknown|' .. item .. ']]'))
	end
	return output
end

function CustomLeague._getGameVersion(game, patch, args)
	local shouldUseAutoPatch = args.autopatch or ''
	local modName = args.modname or ''
	local beta = args.beta or ''
	local epatch = args.epatch or ''
	local sdate = Variables.varDefault('tournament_startdate', _TODAY)
	local edate = Variables.varDefault('tournament_enddate', _TODAY)

	if game ~= '' or patch ~= '' then
		local gameversion
		if game == _GAME_MOD then
			gameversion = modName or 'Mod'
		elseif _GAMES[game] ~= nil then
			gameversion = '[[' .. _GAMES[game][1] .. ']][[Category:' ..
				(beta ~= '' and 'Beta ' or '') .. _GAMES[game][2] .. ' Competitions]]'
		else
			gameversion = '[[Category:' .. (beta ~= '' and 'Beta ' or '') .. ' Competitions]]'
		end

		if (shouldUseAutoPatch == 'false' or game ~= 'lotv') and epatch == '' then
			epatch = patch
		end
		if patch == '' and game == _GAME_LOTV and shouldUseAutoPatch ~= 'false' then
			patch = 'Patch ' .. (
				Autopatch({ sdate }) or '')
		end
		if epatch == '' and game == 'lotv' and shouldUseAutoPatch ~= 'false' then
			epatch = 'Patch ' .. (
				Autopatch({ edate }) or '')
		end

		local patch_display = beta ~= '' and 'Beta ' or ''

		if patch ~= '' then
			if patch == epatch then
				patch_display = patch_display .. '<br/>[[' .. patch .. ']]'
			else
				patch_display = patch_display .. '<br/>[[' .. patch .. ']] &ndash; [[' .. epatch .. ']]'
			end
		end

		--set patch variables
		Variables.varDefine('patch', 'Patch ' .. patch)
		Variables.varDefine('epatch', 'Patch ' .. epatch)

		return gameversion .. patch_display
	end
end

function CustomLeague:createPrizepool(args)
	local cell = Cell:new('Prize pool')
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
		return cell:content()
	end

	local localCurrency = args.localcurrency
	local prizePoolUSD = args.prizepoolusd
	local prizePool = args.prizepool

	if localCurrency == 'text' then
		return cell:content(args.prizepool)
	else
		local display, hasText, hasPlus
		if prizePoolUSD then
			prizePoolUSD, hasText, hasPlus = CustomLeague:_cleanPrizeValue(prizePoolUSD)
		end

		prizePool, hasText, hasPlus = CustomLeague:_cleanPrizeValue(prizePool, localCurrency, hasPlus, hasText)

		if not prizePoolUSD and localCurrency then
			local exchangeDate = Variables.varDefault('tournament_enddate', _TODAY)
			prizePoolUSD =  CustomLeague:_currencyConversion(prizePool, localCurrency:upper(), exchangeDate)
			if not prizePoolUSD then
				error('Invalid local currency "' .. localCurrency .. '"')
			end
		end

		local plusText = hasPlus and '+' or ''
		if prizePoolUSD then
			display = Template.safeExpand(
				mw.getCurrentFrame(),
				'Local currency',
				{localCurrency:lower(), prizepool = CustomLeague:_displayPrizeValue(prizePool, 2) .. plusText}
			) .. '<br>(≃ $' .. CustomLeague:_displayPrizeValue(prizePoolUSD) .. plusText .. ' ' .. _ABBR_USD .. ')'
		elseif prizePool then
			display = '$' .. CustomLeague:_displayPrizeValue(prizePool, 2) .. plusText .. ' ' .. _ABBR_USD
		end
		if hasText then
			display = display .. '[[Category:Pages with text set as prizepool in infobox league]]'
		end

		Variables.varDefine('usd prize', prizePoolUSD or prizePool)
		Variables.varDefine('tournament_prizepoolusd', prizePoolUSD or prizePool)
		Variables.varDefine('local prize', prizePool)

		return cell:content(display)
	end
end

function CustomLeague:_currencyConversion(localPrize, currency, exchangeDate)
	if exchangeDate and currency and currency ~= 'USD' then
		if localPrize then
			local usdPrize = mw.ext.CurrencyExchange.currencyexchange(
				localPrize,
				currency,
				'USD',
				exchangeDate
			)
			if type(usdPrize) == 'number' then
				return usdPrize
			end
		end
	end

	return nil
end

function CustomLeague:_displayPrizeValue(value, numDigits)
	if value == 0 or value == '0' then
		return '-'
	end

	numDigits = tonumber(numDigits or 0) or 0
	local factor = 10^numDigits
	value = math.floor(value * factor + 0.5) / factor

	local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
	if right:len() > 0 then
		local decimal = string.sub('0' .. right, 3)
		right = "." .. decimal .. string.rep('0', 2 - string.len(decimal))
	end
	return left .. (num:reverse():gsub('(%d%d%d)','%1,'):reverse()) .. right
end

function CustomLeague:_cleanPrizeValue(value, currency, oldHasPlus, oldHasText)
	if String.isEmpty(value) then
		return nil, nil, nil
	end

	--remove currency abbreviations
	value = value:gsub('<abbr.*abbr>', ''):gsub(',', '')

	--remove currency symbol
	if currency then
		_ = Template.safeExpand(mw.getCurrentFrame(), 'Local currency', {currency:lower()})
		local symbol = Variables.varDefineMulti('localcurrencysymbol', 'localcurrencysymbolafter') or ''
		value = value:gsub(symbol, '')
	else
		value = value:gsub('%$', '')
	end

	--remove white spaces and &nbsp;
	value = value:gsub('%s', ''):gsub('&nbsp;', '')

	--check if it has a "+" at the end
	local hasPlus = string.match(value, '%+$')
	if hasPlus then
		value = value:gsub('%+$', '')
		hasPlus = true
	end

	--check if additional non numbers are present
	local hasText = string.match(value, '[^%.%d]')
	value = tonumber(value)

	return value, hasText or oldHasText, hasPlus or oldHasPlus
end

function CustomLeague:addCustomContent(infobox, args)
	--player breakdown
	local playerRaceBreakDown = CustomLeague._playerRaceBreakDown(args) or {}
	local playerBreakDownEvent = CustomLeague._playerBreakDownEvent(args) or {}
	local playerNumber = playerRaceBreakDown.playerNumber or playerBreakDownEvent.playerNumber
	infobox:header('Player Breakdown', playerNumber)
	infobox:cell('Number of players', playerNumber)
	infobox:fcell(CustomLeague._playerBreakDownDisplay(playerRaceBreakDown.display))
	infobox:fcell(CustomLeague._playerBreakDownDisplay(playerBreakDownEvent.display))
	Variables.varDefine('tournament_playerNumber', playerNumber)

	--teams section
	if args.team_number or (not String.isEmpty(args.team1)) then
		Variables.varDefine('is_team_tournament', 1)
		infobox:header('Teams', true)
	end
	infobox:cell('Number of teams', args.team_number)
	if not String.isEmpty(args.team1) then
		infobox:header('Teams', true)
		local teams = CustomLeague:_makeBasedListFromArgs(args, 'team', {redirect = false})
		infobox	:centeredCell(unpack(teams))
	end

	--maps
	if not String.isEmpty(args.map1) then
		infobox:header('Maps', true)
		local maps = CustomLeague:_makeBasedListFromArgs(args, 'map', {redirect = true})
		infobox:centeredCell(unpack(maps))
	elseif not String.isEmpty(args['2map1']) then
		infobox:header(args['2maptitle'] or '2v2 Maps', true)
		local maps = CustomLeague:_makeBasedListFromArgs(args, '2map', {redirect = true})
		infobox:centeredCell(unpack(maps))
	elseif not String.isEmpty(args['3map1']) then
		infobox:header(args['3maptitle'] or '3v3 Maps', true)
		local maps = CustomLeague:_makeBasedListFromArgs(args, '3map', {redirect = true})
		infobox:centeredCell(unpack(maps))
	end

    return infobox
end

function CustomLeague._playerBreakDownEvent(args)
	local playerBreakDown = {}
	local codeS = tonumber(args.code_s_number or 0) or 0
	local codeA = tonumber(args.code_a_number or 0) or 0
	local premier = tonumber(args.premier_number or 0) or 0
	local challenger = tonumber(args.challenger_number or 0) or 0
	local playerNumber = codeS + codeA + premier + challenger

	if playerNumber > 0 then
		playerBreakDown.playerNumber = playerNumber
		playerBreakDown.display = {}
		if codeS > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = _SICON .. ' ' .. codeS
		end
		if codeA > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = _AICON .. ' ' .. codeA
		end
		if premier > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = _PICON .. ' ' .. premier
		end
		if challenger > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = _CICON .. ' ' .. challenger
		end
	end
	return playerBreakDown
end

function CustomLeague._playerRaceBreakDown(args)
	local playerBreakDown = {}
	local playerNumber = tonumber(args.player_number or 0) or 0
	local zergNumber = tonumber(args.zerg_number or 0) or 0
	local terranNumbner = tonumber(args.terran_number or 0) or 0
	local protossNumber = tonumber(args.protoss_number or 0) or 0
	local randomNumber = tonumber(args.random_number or 0) or 0
	if playerNumber == 0 then
		playerNumber = zergNumber + terranNumbner + protossNumber + randomNumber
	end

	if playerNumber > 0 then
		playerBreakDown.playerNumber = playerNumber
		if zergNumber + terranNumbner + protossNumber + randomNumber > 0 then
			playerBreakDown.display = {}
			if protossNumber > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'p'})
					.. ' ' .. protossNumber)
			end
			if terranNumbner > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'t'})
					.. ' ' .. terranNumbner)
			end
			if zergNumber > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'z'})
					.. ' ' .. zergNumber)
			end
			if randomNumber > 0 then
				table.insert(playerBreakDown.display, RaceIcon.getSmallIcon({'r'})
					.. ' ' .. randomNumber)
			end
		end
	end
	Variables.varDefine('nbnotableP', protossNumber)
	Variables.varDefine('nbnotableT', terranNumbner)
	Variables.varDefine('nbnotableZ', zergNumber)
	Variables.varDefine('nbnotableR', randomNumber)
	return playerBreakDown
end

function CustomLeague._playerBreakDownDisplay(contents)
    if type(contents) ~= 'table' or contents == {} then
        return nil
    end

    local div = mw.html.create('div')
    local number = #contents
    for _, content in ipairs(contents) do
        local infoboxCustomCell = mw.html.create('div'):addClass('infobox-cell-' .. number
			.. ' infobox-center')
        infoboxCustomCell:wikitext(content)
        div:node(infoboxCustomCell)
    end

    return div
end

function CustomLeague:_makeBasedListFromArgs(args, base, options)
	options = options or {}
	local firstArg = args[base .. '1']
	if options.redirecet then
		firstArg = mw.ext.TeamLiquidIntegration.resolve_redirect(firstArg)
	end
	local foundArgs = {CustomLeague:_makeInternalLink(firstArg)}
	local index  = 2

	while not String.isEmpty(args[base .. index]) do
		local currentArg = args['map' .. index]
		if options.redirecet then
			currentArg = mw.ext.TeamLiquidIntegration.resolve_redirect(currentArg)
		end
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(CustomLeague:_createNoWrappingSpan(
				CustomLeague:_makeInternalLink(currentArg)
			))
		)
		index = index + 1
	end
	
	return foundArgs
end

function CustomLeague:defineCustomPageVariables(args)
	--override vars that need custom handling on sc2
	local game = args.game or ''
	Variables.varDefine('tournament_game', (_GAMES[game] or {})[1] or game)
	Variables.varDefine('tournament_series', mw.ext.TeamLiquidIntegration.resolve_redirect(args.series or ''))

	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', args.tickername or name)
	Variables.varDefine('tournament_abbreviation', args.abbreviation or '')

	--Legacy date vars
	local sdate = Variables.varDefault('tournament_startdate', '')
	local edate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('infobox_date', edate)
	Variables.varDefine('infobox_sdate', sdate)
	Variables.varDefine('infobox_edate', edate)
	Variables.varDefine('date', edate)
	Variables.varDefine('sdate', sdate)
	Variables.varDefine('edate', edate)
	Variables.varDefine('tournament_date', edate)
	Variables.varDefine('formatted_tournament_date', sdate)
	Variables.varDefine('formatted_tournament_edate', edate)

	--SC2 specific vars
	Variables.varDefine('tournament_mode', args.mode or '1v1')
	Variables.varDefine('headtohead', args.headtohead)
	Variables.varDefine('featured', args.featured or 'false')
	--series number
	local seriesNumber = args.number or ''
	local seriesNumberLength = string.len(seriesNumber)
	if seriesNumberLength > 0 then
		seriesNumber = string.rep('0', 5 - seriesNumberLength) .. seriesNumber
	end
	Variables.varDefine('tournament_series_number', series_number)
	--check if tournament is finished
	local finished = args.finished
	local queryDate = Variables.varDefault('tournament_enddate', '2999-99-99')
	if finished ~= 'true' and os.date('%Y-%m-%d') >= queryDate then
		local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] AND [[participant::!Definitions]] AND [[placement::1]]',
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
	local monthAndDay = string.match(edate, '%d%d-%d%d') or ''
	Variables.varDefine('Month_Day', monthAndDay)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.series = mw.ext.TeamLiquidIntegration.resolve_redirect(lpdbData.series or '')
	lpdbData.game = string.lower(Variables.varDefault('tournament_game', ''))
	lpdbData.patch = Variables.varDefault('patch', '')
	lpdbData.endpatch = Variables.varDefaultMulti('epatch', 'patch', '')
	local status = args.status
		or Variables.varDefault('cancelled tournament', '') == 'true' and 'cancelled'
		or Variables.varDefault('tournament_finished', '') == 'true' and 'finished'
	lpdbData.status = status
	lpdbData.shortname = lpdbData.shortname or args.abbreviation
	lpdbData.maps = CustomLeague:_concatArgs(args, 'map')
	lpdbData.participantsnumber = Variables.varDefault('tournament_playerNumber', args.team_number or 0)

	return lpdbData
end

function CustomLeague:_concatArgs(args, base)
	local foundArgs = {args[base] or args[base .. '1']}
	local index = 2
	while not String.isEmpty(args[base .. index]) do
		table.insert(foundArgs, args[base .. index])
		index = index + 1
	end

	return table.concat(foundArgs, ';')
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague:_makeInternalLink(content)
	return '[[' .. content .. ']]'
end

--here
--kick this if PR #286 goes through
function CustomLeague:exists(page)
	local existingPage = mw.title.new(page)

	-- In some cases we might have gotten an external link,
	-- which will mean `existingPage` will equal nil
	if existingPage == nil then
		return false
	end

	return existingPage.exists
end

return CustomLeague
