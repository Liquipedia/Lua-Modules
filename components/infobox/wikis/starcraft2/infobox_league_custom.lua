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
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local PageLink = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown', {requireDevIfEnabled = true})

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

local GREATER_EQUAL = '&#8805;'
local PRIZE_POOL_ROUND_PRECISION = 2
local TODAY = os.date('%Y-%m-%d', os.time())

local GAME_MOD = 'mod'
local GAME_LOTV = Game.name{game = 'lotv'}

local SICON = '[[File:Sicon.png|text-bottom|Code S|link=Code S]]'
local AICON = '[[File:Aicon.png|text-bottom|Code A]]'
local PICON = '[[File:PIcon.png|text-bottom|Premier League]]'
local CICON = '[[File:CIcon.png|text-bottom|Challenger League]]'

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = league.args

	_args.game = _args.game == GAME_MOD and GAME_MOD or Game.name{game = _args.game}
	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.shouldStore = CustomLeague.shouldStore
	league.liquipediaTierHighlighted = CustomLeague.liquipediaTierHighlighted
	league.getWikiCategories = CustomLeague.getWikiCategories

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
		local raceBreakdown = RaceBreakdown.run(_args) or {}
		local playerBreakDownEvent = CustomLeague._playerBreakDownEvent() or {}
		_args.player_number = raceBreakdown.total or playerBreakDownEvent.playerNumber

		if _args.player_number and _args.player_number > 0 then
			Array.appendWith(widgets,
				Title{name = 'Player Breakdown'},
				Cell{name = 'Number of Players', content = {raceBreakdown.total}},
				Breakdown{content = raceBreakdown.display, classes = { 'infobox-center' }},
				Breakdown{content = playerBreakDownEvent.display, classes = {'infobox-center'}}
			)
		end

		--teams section
		if _args.team_number or String.isNotEmpty(_args.team1) then
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
	---@cast maps -nil

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
	if String.isEmpty(_args.prizepool) and String.isEmpty(_args.prizepoolusd) then
		return
	end

	local localCurrency = _args.localcurrency

	if localCurrency == 'text' then
		return _args.prizepool
	else
		local prizePoolUSD = _args.prizepoolusd
		local prizePool = _args.prizepool

		if not localCurrency and not prizePoolUSD then
			prizePoolUSD = prizePool
			prizePool = nil
		end

		local hasPlus
		prizePoolUSD, hasPlus = CustomLeague:_removePlus(prizePoolUSD)
		prizePool, hasPlus = CustomLeague:_removePlus(prizePool, hasPlus)

		return (hasPlus and (GREATER_EQUAL .. ' ') or '') .. InfoboxPrizePool.display{
			prizepool = prizePool,
			prizepoolusd = prizePoolUSD,
			currency = localCurrency,
			rate = _args.currency_rate,
			date = _args.currency_date or Variables.varDefault('tournament_enddate'),
			displayRoundPrecision = PRIZE_POOL_ROUND_PRECISION,
		}
	end
end

function CustomLeague:_removePlus(inputValue, alreadyHasPlus)
	if not inputValue then
		return inputValue, alreadyHasPlus
	end

	local hasPlus = string.sub(inputValue, -1) == '+'
	if hasPlus then
		inputValue = string.sub(inputValue, 0, -1)
	end

	return inputValue, hasPlus or alreadyHasPlus
end

function CustomLeague._getGameVersion()
	local game = _args.game
	local modName = _args.modname
	local betaPrefix = String.isNotEmpty(_args.beta) and 'Beta ' or ''

	local gameVersion
	if game == GAME_MOD then
		gameVersion = modName or 'Mod'
	else
		gameVersion = '[[' .. game .. ']]'
	end

	local patchDisplay = betaPrefix
	if _args.patch then
		patchDisplay = patchDisplay .. '<br/>[[' .. _args.patch .. ']]'
		if _args.patch ~= _args.epatch then
			patchDisplay = patchDisplay .. ' &ndash; [[' .. _args.epatch .. ']]'
		end
	end

	return gameVersion .. patchDisplay
end

function CustomLeague._setPatchData()
	local patchPrefix = 'Patch '

	if _args.patch and _args.epatch then
		_args.patch = patchPrefix .. _args.patch
		_args.epatch = patchPrefix .. _args.epatch

		return
	end

	local startDate = Variables.varDefault('tournament_startdate', TODAY)
	local endDate = Variables.varDefault('tournament_enddate', TODAY)

	if _args.game == GAME_LOTV and Logic.nilOr(Logic.readBoolOrNil(_args.autopatch), true) then
		_args.patch = _args.patch or Autopatch._main{CustomLeague._retrievePatchDate(startDate)}
		_args.epatch = _args.epatch or Autopatch._main{CustomLeague._retrievePatchDate(endDate)}
	end

	if not _args.patch then
		return
	elseif not _args.epatch then
		_args.epatch = _args.patch
	end

	_args.patch = patchPrefix .. _args.patch
	_args.epatch = patchPrefix .. _args.epatch

	return
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
		local previous = String.isNotEmpty(_args.previous) and _args.previous or nil
		local next = String.isNotEmpty(_args.next) and _args.next or nil
		local nextPage = not next and
			title.basePageTitle:subPageTitle(tostring(number + 1)).fullText
		local previousPage = not previous and
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

function CustomLeague:defineCustomPageVariables(args)
	--override var to standardize its entries
	Variables.varDefine('tournament_game', args.game)

	--patch data
	CustomLeague._setPatchData()
	Variables.varDefine('patch', args.patch)
	Variables.varDefine('epatch', args.epatch)

	--SC2 specific vars
	Variables.varDefine('tournament_mode', args.mode or '1v1')
	Variables.varDefine('headtohead', args.headtohead or 'true')
	Variables.varDefine('tournament_publishertier', tostring(Logic.readBool(args.featured)))
	--series number
	local seriesNumber = args.number
	if Logic.isNumeric(seriesNumber) then
		seriesNumber = string.format('%05i', seriesNumber)
		Variables.varDefine('tournament_series_number', seriesNumber)
	end
	--check if tournament is finished
	local finished = Logic.readBool(args.finished)
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
		local mapArray = mw.text.split(map, '|')
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(mapArray[1]),
			displayname = _args[prefix .. mapIndex .. 'display'] or mapArray[#mapArray],
		}
	end)
end

function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.game = args.game
	lpdbData.patch = Variables.varDefault('patch', '')
	lpdbData.endpatch = Variables.varDefaultMulti('epatch', 'patch', '')
	local status = args.status
		or Logic.readBool(Variables.varDefault('cancelled tournament')) and 'cancelled'
		or Logic.readBool(Variables.varDefault('tournament_finished')) and 'finished'
	lpdbData.status = status
	lpdbData.maps = Variables.varDefault('tournament_maps')
	lpdbData.next = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_next))
	lpdbData.previous = mw.ext.TeamLiquidIntegration.resolve_redirect(CustomLeague:_getPageNameFromChronology(_previous))

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

function CustomLeague:getWikiCategories(args)
	if args.game == GAME_MOD then
		return {}
	end

	local betaPrefix = String.isNotEmpty(args.beta) and 'Beta ' or ''
	local gameAbbr = Game.abbreviation{game = args.game}
	return {betaPrefix .. gameAbbr .. ' Competitions'}
end

function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.featured)
end

return CustomLeague
