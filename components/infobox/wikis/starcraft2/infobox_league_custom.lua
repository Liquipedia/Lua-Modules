---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AllowedServers = require('Module:Server')
local Array = require('Module:Array')
local Autopatch = require('Module:Automated Patch')
local Class = require('Module:Class')
local Currency = require('Module:Currency')
local Faction = require('Module:Faction')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Chronology = Widgets.Chronology
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _league
local _next
local _previous

local ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
local TODAY = os.date('%Y-%m-%d', os.time())
local TIER_MODE_TYPES = 'types'
local TIER_MODE_TIERS = 'tiers'

local GAME_WOL = 'wol'
local GAME_HOTS = 'hots'
local GAME_LOTV = 'lotv'
local GAME_MOD = 'mod'

local GAMES = {
	[GAME_WOL] = {'Wings of Liberty', 'WoL'},
	[GAME_HOTS] = {'Heart of the Swarm', 'HotS'},
	[GAME_LOTV] = {'Legacy of the Void', 'LotV'},
	[GAME_MOD] = {'mod', 'mod'}
}
local SICON = '[[File:Sicon.png|text-bottom|Code S|link=Code S]]'
local AICON = '[[File:Aicon.png|text-bottom|Code A]]'
local PICON = '[[File:PIcon.png|text-bottom|Premier League]]'
local CICON = '[[File:CIcon.png|text-bottom|Challenger League]]'

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = league.args

	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.shouldStore = CustomLeague.shouldStore

	return league:createInfobox()
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
				content = {CustomLeague:_createLiquipediaTierDisplay()},
				classes = {Logic.readBool(_args.featured) and 'tournament-highlighted-bg' or ''}
			},
		}
	elseif id == 'chronology' then
		local content = CustomLeague._getChronologyData()
		if String.isNotEmpty(content.previous) or String.isNotEmpty(content.next) then
			return {
				Title{name = 'Chronology'},
				Chronology{
					content = content
				}
			}
		end
	elseif id == 'customcontent' then
		--player breakdown
		local playerRaceBreakDown = CustomLeague._playerRaceBreakDown() or {}
		local playerBreakDownEvent = CustomLeague._playerBreakDownEvent() or {}
		--make playerNumber available for commons category check
		_args.player_number = playerRaceBreakDown.playerNumber or playerBreakDownEvent.playerNumber
		local playerNumber = _args.player_number or 0
		Variables.varDefine('tournament_playerNumber', playerNumber)
		if playerNumber > 0 then
			table.insert(widgets, Title{name = 'Player breakdown'})
			table.insert(widgets, Cell{name = 'Number of players', content = {playerNumber}})
			table.insert(widgets, Breakdown{content = playerRaceBreakDown.display, classes = {'infobox-center'}})
			table.insert(widgets, Breakdown{content = playerBreakDownEvent.display, classes = {'infobox-center'}})
		end

		--teams section
		if _args.team_number or String.isNotEmpty(_args.team1) then
			Variables.varDefine('is_team_tournament', 1)
			table.insert(widgets, Title{name = 'Teams'})
		end
		table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
		if String.isNotEmpty(_args.team1) then
			local teams = CustomLeague:_makeBasedListFromArgs('team')
			table.insert(widgets, Center{content = teams})
		end

		--maps
		if String.isNotEmpty(_args.map1) then
			table.insert(widgets, Title{name = _args['maptitle'] or 'Maps'})
			table.insert(widgets, Center{content = CustomLeague._mapsDisplay('map')})
		end

		if String.isNotEmpty(_args['2map1']) then
			table.insert(widgets, Title{name = _args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{content = CustomLeague._mapsDisplay('2map')})
		end

		if String.isNotEmpty(_args['3map1']) then
			table.insert(widgets, Title{name = _args['3maptitle'] or '3v3 Maps'})
			table.insert(widgets, Center{content = CustomLeague._mapsDisplay('3map')})
		end
	end
	return widgets
end

function CustomLeague._mapsDisplay(prefix)
	local maps = CustomLeague._getMaps(prefix)

	return {table.concat(
		Array.map(maps, function(mapData)
			return tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, mapData.displayname, mapData.link)
			))
		end),
		'&nbsp;• '
	)}
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
			local exchangeDate = Variables.varDefault('tournament_enddate', TODAY)
			prizePoolUSD = CustomLeague:_currencyConversion(prizePool, localCurrency:upper(), exchangeDate)
			if not prizePoolUSD then
				error('Invalid local currency "' .. localCurrency .. '"')
			end
		end

		local plusText = hasPlus and '+' or ''
		if prizePoolUSD and prizePool then
			display = Currency.display((localCurrency or ''):lower(), CustomLeague:_displayPrizeValue(prizePool, 2) .. plusText)
				.. '<br>(≃ $' .. CustomLeague:_displayPrizeValue(prizePoolUSD) .. plusText .. ' ' .. ABBR_USD .. ')'
		elseif prizePool or prizePoolUSD then
			display = '$' .. CustomLeague:_displayPrizeValue(prizePool or prizePoolUSD, 2) .. plusText .. ' ' .. ABBR_USD
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

--function for custom tier handling
function CustomLeague._createLiquipediaTierDisplay()
	local tier = _args.liquipediatier
	local tierType = _args.liquipediatiertype
	if String.isEmpty(tier) then
		return nil
	end

	local teamEventCategoryInfix = (String.isNotEmpty(_args.team_number) or String.isNotEmpty(_args.team1))
		and 'Team ' or ''

	local function buildTierText(tierString, tierMode)
		local tierText = Tier.text[tierMode][tierString]
		if not tierText then
			tierMode = tierMode == TIER_MODE_TYPES and 'Tiertype' or 'Tier'
			table.insert(
				_league.warnings,
				tierString .. ' is not a known Liquipedia ' .. tierMode
					.. '[[Category:Pages with invalid ' .. tierMode .. ']]'
			)
			return ''
		else
			return tierText
		end
	end

	tier = buildTierText(tier, TIER_MODE_TIERS)

	local tierLink = tier .. ' Tournaments'
	local tierCategory = '[[Category:' .. tier .. ' ' .. teamEventCategoryInfix .. 'Tournaments]]'
	local tierDisplay
	if String.isNotEmpty(tierType) then
		tierType = buildTierText(tierType:lower(), TIER_MODE_TYPES)
		tierDisplay = tierType .. '&nbsp;(' .. tier .. ')'
	else
		tierDisplay = tier
	end

	return '[[' .. tierLink .. '|' .. tierDisplay .. ']]' .. tierCategory
end

function CustomLeague._getGameVersion()
	local game = string.lower(_args.game or '')
	local patch = _args.patch or ''
	local shouldUseAutoPatch = (_args.autopatch or '') ~= 'false'
	local modName = _args.modname
	local betaPrefix = String.isNotEmpty(_args.beta) and 'Beta ' or ''
	local endPatch = _args.epatch
	local startDate = Variables.varDefault('tournament_startdate', TODAY)
	local endDate = Variables.varDefault('tournament_enddate', TODAY)

	if String.isNotEmpty(game) or String.isNotEmpty(patch) then
		local gameVersion
		if game == GAME_MOD then
			gameVersion = modName or 'Mod'
		elseif GAMES[game] then
			gameVersion = '[[' .. GAMES[game][1] .. ']]' ..
				'[[Category:' .. betaPrefix .. GAMES[game][2] .. ' Competitions]]'
		else
			gameVersion = '[[Category:' .. betaPrefix .. 'Competitions]]'
		end

		if game == GAME_LOTV and shouldUseAutoPatch then
			if String.isEmpty(patch) then
				patch = 'Patch ' .. (Autopatch._main({CustomLeague._retrievePatchDate(startDate)}) or '')
			end
			if String.isEmpty(endPatch) then
				endPatch = 'Patch ' .. (Autopatch._main({CustomLeague._retrievePatchDate(endDate)}) or '')
			end
		elseif String.isEmpty(endPatch) then
			endPatch = patch
		end

		local patchDisplay = betaPrefix

		if String.isNotEmpty(patch) then
			patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']]'
			if patch ~= endPatch then
				patchDisplay = patchDisplay .. ' &ndash; [[' .. endPatch .. ']]'
			end
		end

		--set patch variables
		Variables.varDefine('patch', patch)
		Variables.varDefine('epatch', endPatch)

		return gameVersion .. patchDisplay
	end
end

function CustomLeague._retrievePatchDate(dateEntry)
	return String.isNotEmpty(dateEntry)
		and dateEntry:lower() ~= 'tbd'
		and dateEntry:lower() ~= 'tba'
		and dateEntry or TODAY
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
	local number = tonumber(title.subpageText)
	local automateChronology = String.isNotEmpty(_args.series)
		and number
		and tonumber(_args.number) == number
		and title.subpageText ~= title.text
		and Logic.readBool(_args.auto_chronology or true)
		and (String.isEmpty(_args.next) or String.isEmpty(_args.previous))

	if automateChronology then
		local previous = String.isNotEmpty(_args.previous) and _args.previous
		local next = String.isNotEmpty(_args.next) and _args.next
		local nextPage = String.isEmpty(_args.next) and
			title.basePageTitle:subPageTitle(tostring(number + 1)).fullText
		local previousPage = String.isEmpty(_args.previous) and
			title.basePageTitle:subPageTitle(tostring(number - 1)).fullText

		if not next and PageLink.exists(nextPage) then
			next = nextPage .. '|#' .. tostring(number + 1)
		end

		if not previous and 1 < number and PageLink.exists(previousPage) then
			previous = previousPage .. '|#' .. tostring(number - 1)
		end

		return next or nil, previous or nil
	else
		return _args.next, _args.previous
	end
end

function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(args.disable_lpdb) and
		not Logic.readBool(args.disable_storage) and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage', 'false'))
end

function CustomLeague:_getServer()
	if String.isEmpty(_args.server) then
		return nil
	end
	local server = _args.server
	local servers = mw.text.split(server, '/')

	local output = ''
	for key, item in ipairs(servers or {}) do
		item = string.lower(item)
		if key ~= 1 then
			output = output .. ' / '
		end
		item = mw.text.trim(item)
		output = output .. (AllowedServers[string.lower(item)] or ('[[Category:Server Unknown|' .. item .. ']]'))
	end
	return output
end

function CustomLeague:_currencyConversion(localPrize, currency, exchangeDate)
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
		return nil, oldHasText, nil
	end

	--remove white spaces, '&nbsp;' and ','
	value = string.gsub(value, '%s', '')
	value = string.gsub(value, '&nbsp;', '')
	value = string.gsub(value, ',', '')
	value = string.gsub(value, '%$', '')

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
	local codeS = tonumber(_args.code_s_number) or 0
	local codeA = tonumber(_args.code_a_number) or 0
	local premier = tonumber(_args.premier_number) or 0
	local challenger = tonumber(_args.challenger_number) or 0
	local playerNumber = codeS + codeA + premier + challenger

	if playerNumber > 0 then
		playerBreakDown.playerNumber = playerNumber
		playerBreakDown.display = {}
		if codeS > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = SICON .. ' ' .. codeS
		end
		if codeA > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = AICON .. ' ' .. codeA
		end
		if premier > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = PICON .. ' ' .. premier
		end
		if challenger > 0 then
			playerBreakDown.display[#playerBreakDown.display + 1] = CICON .. ' ' .. challenger
		end
	end
	return playerBreakDown or {}
end

function CustomLeague._playerRaceBreakDown()
	local playerBreakDown = {}
	local playerNumber = tonumber(_args.player_number) or 0
	local zergNumber = tonumber(_args.zerg_number) or 0
	local terranNumbner = tonumber(_args.terran_number) or 0
	local protossNumber = tonumber(_args.protoss_number) or 0
	local randomNumber = tonumber(_args.random_number) or 0
	if playerNumber == 0 then
		playerNumber = zergNumber + terranNumbner + protossNumber + randomNumber
	end

	if playerNumber > 0 then
		playerBreakDown.playerNumber = playerNumber
		if zergNumber + terranNumbner + protossNumber + randomNumber > 0 then
			playerBreakDown.display = {}
			if protossNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'p'} .. ' ' .. protossNumber)
			end
			if terranNumbner > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 't'} .. ' ' .. terranNumbner)
			end
			if zergNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'z'} .. ' ' .. zergNumber)
			end
			if randomNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'r'} .. ' ' .. randomNumber)
			end
		end
	end
	Variables.varDefine('nbnotableP', protossNumber)
	Variables.varDefine('nbnotableT', terranNumbner)
	Variables.varDefine('nbnotableZ', zergNumber)
	Variables.varDefine('nbnotableR', randomNumber)
	return playerBreakDown or {}
end

function CustomLeague:_makeBasedListFromArgs(prefix)
	local foundArgs = {}
	for key, linkValue in Table.iter.pairsByPrefix(_args, prefix) do
		local displayValue = String.isNotEmpty(_args[key .. 'display'])
			and _args[key .. 'display']
			or linkValue

		table.insert(
			foundArgs,
			tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, displayValue, linkValue)
			))
		)
	end

	return {table.concat(foundArgs, '&nbsp;• ')}
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', _args.tickername or name)
	Variables.varDefine('tournament_abbreviation', _args.abbreviation or '')

	--Legacy tier(type) vars
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype', ''))
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))

	--override var to standardize its entries
	Variables.varDefine('tournament_game', CustomLeague._getGameStorage(_args.game))

	--SC2 specific vars
	Variables.varDefine('tournament_mode', _args.mode or '1v1')
	Variables.varDefine('headtohead', _args.headtohead or 'true')
	Variables.varDefine('featured', tostring(Logic.readBool(_args.featured)))
	--series number
	local seriesNumber = _args.number
	if Logic.isNumeric(seriesNumber) then
		seriesNumber = string.format('%05i', seriesNumber)
		Variables.varDefine('tournament_series_number', seriesNumber)
	end
	--check if tournament is finished
	local finished = Logic.readBool(_args.finished)
	local queryDate = Variables.varDefault('tournament_enddate', '2999-99-99')
	if not finished and os.date('%Y-%m-%d') >= queryDate then
		local data = mw.ext.LiquipediaDB.lpdb('placement', {
			conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
				.. 'AND [[opponentname::!TBD]] AND [[placement::1]]',
			query = 'date',
			order = 'date asc',
			limit = 1
		})
		if data and data[1] then
			finished = true
		end
	end
	Variables.varDefine('tournament_finished', tostring(finished))
	--month and day
	local monthAndDay = string.match(Variables.varDefault('tournament_enddate', ''), '%d%d-%d%d') or ''
	Variables.varDefine('Month_Day', monthAndDay)

	--maps
	local maps = CustomLeague._getMaps('map')
	Variables.varDefine('tournament_maps', maps and Json.stringify(maps) or '')
end

function CustomLeague._getMaps(prefix)
	if String.isEmpty(_args[prefix .. '1']) then
		return
	end
	local mapArgs = _league:getAllArgsForBase(_args, prefix)

	return Table.map(mapArgs, function(mapIndex, map)
		map = mw.text.split(map, '|')
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(map[1]),
			displayname = _args[prefix .. mapIndex .. 'display'] or map[#map],
		}
	end)
end

function CustomLeague:addToLpdb(lpdbData)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.game = CustomLeague._getGameStorage(_args.game)
	lpdbData.patch = Variables.varDefault('patch', '')
	lpdbData.endpatch = Variables.varDefaultMulti('epatch', 'patch', '')
	local status = _args.status
		or Logic.readBool(Variables.varDefault('cancelled tournament')) and 'cancelled'
		or Logic.readBool(Variables.varDefault('tournament_finished')) and 'finished'
	lpdbData.status = status
	lpdbData.maps = Variables.varDefault('tournament_maps')
	local participantsNumber = tonumber(Variables.varDefault('tournament_playerNumber')) or 0
	if participantsNumber == 0 then
		participantsNumber = _args.team_number or 0
	end
	lpdbData.participantsnumber = participantsNumber
	lpdbData.next = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_next))
	lpdbData.previous = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_previous))
	lpdbData.publishertier = Variables.varDefault('featured')

	lpdbData.extradata.seriesnumber = Variables.varDefault('tournament_series_number')

	return lpdbData
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

function CustomLeague._getGameStorage(gameInput)
	return (GAMES[string.lower(gameInput or '')] or {})[1] or GAMES[GAME_WOL][1]
end

return CustomLeague
