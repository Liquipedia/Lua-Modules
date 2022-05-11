---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local League = require('Module:Infobox/League')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Autopatch = require('Module:Automated Patch')
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
local _league
local _next
local _previous

local _ABBR_USD = '<abbr title="United States Dollar">USD</abbr>'
local _TODAY = os.date('%Y-%m-%d', os.time())
local _TIER_MODE_TYPES = 'types'
local _TIER_MODE_TIERS = 'tiers'

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
	_league = league
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
				content = {CustomLeague:_createLiquipediaTierDisplay()},
				classes = {_args.featured == 'true' and 'sc2premier-highlighted' or ''}
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
		local playerNumber = playerRaceBreakDown.playerNumber or playerBreakDownEvent.playerNumber or 0
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
			table.insert(widgets, Title{name = 'Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('map')})
		elseif String.isNotEmpty(_args['2map1']) then
			table.insert(widgets, Title{name = _args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{content = CustomLeague:_makeBasedListFromArgs('2map')})
		elseif String.isNotEmpty(_args['3map1']) then
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
				{(localCurrency or ''):lower(), prizepool = CustomLeague:_displayPrizeValue(prizePool, 2) .. plusText}
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

--function for custom tier handling
function CustomLeague._createLiquipediaTierDisplay()
	local tier = _args.liquipediatier
	local tierType = _args.liquipediatiertype or _args.tiertype
	if String.isEmpty(tier) then
		return nil
	end

	local teamEventCategoryInfix = (String.isNotEmpty(_args.team_number) or String.isNotEmpty(_args.team1))
		and 'Team ' or ''

	local function buildTierText(tierString, tierMode)
		local tierText = Tier.text[tierMode][tierString]
		if not tierText then
			tierMode = tierMode == _TIER_MODE_TYPES and 'Tiertype' or 'Tier'
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

	tier = buildTierText(tier, _TIER_MODE_TIERS)

	local tierLink = tier .. ' Tournaments'
	local tierCategory = '[[Category:' .. tier .. ' ' .. teamEventCategoryInfix .. 'Tournaments]]'
	local tierDisplay
	if String.isNotEmpty(tierType) then
		tierType = buildTierText(tierType:lower(), _TIER_MODE_TYPES)
		tierDisplay = tierDisplay .. tierType .. '&nbsp;(' .. tier .. ')]]'
	else
		tierDisplay = tierDisplay .. tier .. ']]'
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
	local startDate = _args.sdate
	local endDate = _args.edate

	if String.isNotEmpty(game) or String.isNotEmpty(patch) then
		local gameVersion
		if game == _GAME_MOD then
			gameVersion = modName or 'Mod'
		elseif _GAMES[game] then
			gameVersion = '[[' .. _GAMES[game][1] .. ']]' ..
				'[[Category:' .. betaPrefix .. _GAMES[game][2] .. ' Competitions]]'
		else
			gameVersion = '[[Category:' .. betaPrefix .. 'Competitions]]'
		end

		if game == _GAME_LOTV and shouldUseAutoPatch then
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
			if patch == endPatch then
				patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']]'
			else
				patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']] &ndash; [[' .. endPatch .. ']]'
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
		and dateEntry or _TODAY
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

		return next or nil, previous or nil
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
		return nil, oldHasText, nil
	end

	--remove white spaces, '&nbsp;' and ','
	value = string.gsub(value, '%s', '')
	value = string.gsub(value, '&nbsp;', '')
	value = string.gsub(value, ',', '')

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

	local tierType = _args.liquipediatiertype or _args.tiertype or ''
	--overwrite wiki var `tournament_liquipediatiertype` to allow `args.tiertype` as alias entry point for tiertype
	Variables.varDefine('tournament_liquipediatiertype', tierType)
	--Legacy tier(type) vars
	Variables.varDefine('tournament_tiertype', tierType)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))

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
	local monthAndDay = string.match(Variables.varDefault('tournament_enddate', ''), '%d%d-%d%d') or ''
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
	while String.isNotEmpty(_args[base .. index]) do
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
