---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local Autopatch = require('Module:Automated Patch')._main
local Tier = require('Module:Tier')
local Namespace = require('Module:Namespace')
local AllowedServers = require('Module:Server')
local RaceIcon = require('Module:RaceIcon')
local PageLink = require('Module:Page')
local Class = require('Module:Class')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Title = require('Module:Infobox/Widget/Title')
local Center = require('Module:Infobox/Widget/Center')
local Breakdown = require('Module:Infobox/Widget/Breakdown')
local Chronology = require('Module:Infobox/Widget/Chronology')

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _next
local _previous

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
	_args = league.args

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.shouldStore = CustomLeague.shouldStore

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					CustomLeague._getGameVersion()
				}},
			Cell{name = 'Server', content = {CustomLeague:_getServer()}}
			}
	elseif id == 'prizepool' then
		return {
			Cell{
				name = 'Prize pool',
				content = {CustomLeague:_createPrizepool()},
			},
		}
	elseif id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {CustomLeague:_createTierDisplay()},
				classes = {_args.featured == 'true' and 'sc2premier-highlighted' or ''}
			},
		}
	elseif id == 'chronology' and not (String.isEmpty(_args.previous) and String.isEmpty(_args.next)) then
		return {
			Title{name = 'Chronology'},
			Chronology{
				content = {CustomLeague._getChronologyData()}
			}
		}
	elseif id == 'customcontent' then
		--player breakdown
		local playerRaceBreakDown = CustomLeague._playerRaceBreakDown() or {}
		local playerBreakDownEvent = CustomLeague._playerBreakDownEvent() or {}
		local playerNumber = playerRaceBreakDown.playerNumber or playerBreakDownEvent.playerNumber or 0
		Variables.varDefine('tournament_playerNumber', playerNumber)
		if playerNumber > 0 then
			table.insert(widgets, Title{name = 'Player breakdown'})
			table.insert(widgets, Cell{name = 'Number of players', content = {playerNumber}})
			table.insert(widgets, Breakdown{content = playerRaceBreakDown.display, classes = {'infobox-center'}})
			table.insert(widgets, Breakdown{content = playerBreakDownEvent.display, classes = {'infobox-center'}})
		end

		--teams section
		if _args.team_number or (not String.isEmpty(_args.team1)) then
			Variables.varDefine('is_team_tournament', 1)
			table.insert(widgets, Title{name = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		if not String.isEmpty(_args.team1) then
			local teams = CustomLeague:_makeBasedListFromArgs('team')
			table.insert(widgets, Center{content = teams})
		end

		--maps
		if not String.isEmpty(_args.map1) then
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('map')})
		elseif not String.isEmpty(_args['2map1']) then
			table.insert(widgets, Title{name = _args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('2map')})
		elseif not String.isEmpty(_args['3map1']) then
			table.insert(widgets, Title{name = _args['3maptitle'] or '3v3 Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('3map')})
		end
	end
	return widgets
end

function CustomLeague:_createPrizepool()
	if String.isEmpty(_args.prizepool) and
		String.isEmpty(_args.prizepoolusd) then
		return nil
	end

	local localCurrency = _args.localcurrency
	local prizePoolUSD = _args.prizepoolusd
	local prizePool = _args.prizepool

	if localCurrency == 'text' then
		return prizePool
	else
		local display, hasText, hasPlus
		if prizePoolUSD then
			prizePoolUSD, hasText, hasPlus = CustomLeague:_cleanPrizeValue(prizePoolUSD)
		end

		prizePool, hasText, hasPlus = CustomLeague:_cleanPrizeValue(prizePool, localCurrency, hasPlus, hasText)

		if not prizePoolUSD and localCurrency then
			local exchangeDate = Variables.varDefault('tournament_enddate', _TODAY)
			prizePoolUSD = CustomLeague:_currencyConversion(prizePool, localCurrency:upper(), exchangeDate)
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
			display = (display or _args.prizepool or '') ..
				'[[Category:Pages with text set as prizepool in infobox league]]'
		end

		Variables.varDefine('usd prize', prizePoolUSD or prizePool)
		Variables.varDefine('tournament_prizepoolusd', prizePoolUSD or prizePool)
		Variables.varDefine('local prize', prizePool)

		return display
	end
end

function CustomLeague:_createTierDisplay()
	local tier = _args.liquipediatier or ''
	local tierType = _args.liquipediatiertype or _args.tiertype or ''
	if String.isEmpty(tier) then
		return nil
	end

	local tierText = Tier['text'][tier]
	local hasInvalidTier = tierText == nil
	tierText = tierText or tier

	local hasInvalidTierType = false

	local output = '[[' .. tierText .. ' Tournaments|'

	if not String.isEmpty(tierType) then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil

		output = output .. tierType .. '&nbsp;(' .. tierText .. ')'
	else
		output = output .. tierText
	end

	output = output .. ']]' .. '[[Category:' .. tierText .. ' '

	if _args.team_number or _args.team1 then
		output = output .. 'Team Tournaments]][[Category:Team '
	end

	output = output .. 'Tournaments]]' ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '')

	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_tiertype', tierType)
	return output
end

function CustomLeague._getGameVersion()
	local game = string.lower(_args.game or '')
	local patch = _args.patch or ''
	local shouldUseAutoPatch = _args.autopatch or ''
	local modName = _args.modname or ''
	local beta = _args.beta or ''
	local epatch = _args.epatch or ''
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
		Variables.varDefine('patch', patch)
		Variables.varDefine('epatch', epatch)

		return gameversion .. patch_display
	end
end

function CustomLeague._getChronologyData()
	_next, _previous = CustomLeague._computeChronology()
	return {
		previous = _previous,
		next = _next,
		previous2 = _args.previous2,
		next2 = _args.next2,
		previous3 = _args.previous3,
		next3 = _args.next3,
	}
end

-- Automatically fill in next/previous for touranaments that are part of a series
function CustomLeague._computeChronology()
	-- Criteria for automatic chronology are
	-- - part of a series and numbered
	-- - the subpage name matches the number
	-- - prev or next are unspecified
	-- - and not suppressed via auto_chronology=false
	local title = mw.title.getCurrentTitle()
	local number = tonumber(title.subpageText or '')
	local automateChronology =
		(_args.series or '') ~= ''
		and number ~= nil
		and tonumber(_args.number or '') == number
		and title.subpageText ~= title.text
		and _args.auto_chronology ~= 'false'
		and ((_args.next or '') == '' or (_args.previous or '') == '')

	if automateChronology then
		local previous = (_args.previous or '') ~= '' and _args.previous
		local next = (_args.next or '') ~= '' and _args.next
		local nextPage = (_args.next or '') == '' and
			title.basePageTitle:subPageTitle(tostring(number + 1)).fullText
		local previousPage = (_args.previous or '') == '' and
			title.basePageTitle:subPageTitle(tostring(number - 1)).fullText

		if not next and PageLink.exists(nextPage) then
			next = nextPage .. '|#' .. tostring(number + 1)
		end

		if not previous and 1 < number and PageLink.exists(previousPage) then
			previous = previousPage .. '|#' .. tostring(number - 1)
		end

		return next, previous
	else
		return _args.next, _args.previous
	end
end

function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		args.disable_smw ~= 'true' and
		args.disable_lpdb ~= 'true' and
		args.disable_storage ~= 'true' and
		Variables.varDefault('disable_SMW_storage', 'false') ~= 'true'
end

function CustomLeague:_getServer()
	if String.isEmpty(_args.server) then
		return nil
	end
	local server = _args.server
	--remove possible whitespaces around '/'
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
	if String.isEmpty(value) or value == 0 or value == '0' then
		return '-'
	end

	numDigits = tonumber(numDigits or 0) or 0
	local factor = 10^numDigits
	value = math.floor(value * factor + 0.5) / factor

	--split value into
	--left = first digit
	--num = all remaining digits before a possible '.'
	--right = the '.' and all digits after it (unless they are all 0 or do not exist)
	local left, num, right = string.match(value, '^([^%d]*%d)(%d*)(.-)$')
	if right:len() > 0 then
		local decimal = string.sub('0' .. right, 3)
		right = '.' .. decimal .. string.rep('0', 2 - string.len(decimal))
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
		Template.safeExpand(mw.getCurrentFrame(), 'Local currency', {currency:lower()})
		local symbol = Variables.varDefaultMulti('localcurrencysymbol', 'localcurrencysymbolafter') or ''
		value = value:gsub(symbol, '')
	else
		value = value:gsub('%$', '')
	end

	--remove white spaces and &nbsp;
	value = value:gsub('%s', ''):gsub('&nbsp;', '')

	--check if it has a '+' at the end
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

function CustomLeague._playerBreakDownEvent()
	local playerBreakDown = {}
	local codeS = tonumber(_args.code_s_number or 0) or 0
	local codeA = tonumber(_args.code_a_number or 0) or 0
	local premier = tonumber(_args.premier_number or 0) or 0
	local challenger = tonumber(_args.challenger_number or 0) or 0
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
	return playerBreakDown or {}
end

function CustomLeague._playerRaceBreakDown()
	local playerBreakDown = {}
	local playerNumber = tonumber(_args.player_number or 0) or 0
	local zergNumber = tonumber(_args.zerg_number or 0) or 0
	local terranNumbner = tonumber(_args.terran_number or 0) or 0
	local protossNumber = tonumber(_args.protoss_number or 0) or 0
	local randomNumber = tonumber(_args.random_number or 0) or 0
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
	return playerBreakDown or {}
end

function CustomLeague:_makeBasedListFromArgs(base)
	local firstArg = _args[base .. '1']
	local foundArgs = {PageLink.makeInternalLink({}, firstArg)}
	local index = 2

	while not String.isEmpty(_args[base .. index]) do
		local currentArg = _args[base .. index]
		table.insert(foundArgs, '&nbsp;• ' ..
			tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, currentArg)
			))
		)
		index = index + 1
	end

	return foundArgs
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', _args.tickername or name)
	Variables.varDefine('tournament_abbreviation', _args.abbreviation or '')

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

	--override var to standardize its entries
	Variables.varDefine('tournament_game', (_GAMES[string.lower(_args.game)] or {})[1] or _GAMES[_GAME_WOL][1])

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
	local monthAndDay = string.match(edate, '%d%d-%d%d') or ''
	Variables.varDefine('Month_Day', monthAndDay)
end

function CustomLeague:addToLpdb(lpdbData)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.patch = Variables.varDefault('patch', '')
	lpdbData.endpatch = Variables.varDefaultMulti('epatch', 'patch', '')
	local status = _args.status
		or Variables.varDefault('cancelled tournament', '') == 'true' and 'cancelled'
		or Variables.varDefault('tournament_finished', '') == 'true' and 'finished'
	lpdbData.status = status
	lpdbData.maps = CustomLeague:_concatArgs('map')
	lpdbData.participantsnumber = Variables.varDefault('tournament_playerNumber', _args.team_number or 0)
	lpdbData.next = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_next))
	lpdbData.previous = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_previous))

	return lpdbData
end

function CustomLeague:_concatArgs(base)
	local firstArg = _args[base] or _args[base .. '1']
	if String.isEmpty(firstArg) then
		return nil
	end
	local foundArgs = {mw.ext.TeamLiquidIntegration.resolve_redirect(firstArg)}
	local index = 2
	while not String.isEmpty(_args[base .. index]) do
		table.insert(foundArgs,
			mw.ext.TeamLiquidIntegration.resolve_redirect(_args[base .. index])
		)
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

function CustomLeague:_getPageNameFromChronology(item)
	if String.isEmpty(item) then
		return ''
	end

	return mw.text.split(item, '|')[1]
end

return CustomLeague
