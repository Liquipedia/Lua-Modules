---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local Faction = require('Module:Faction')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local PageLink = require('Module:Page')
local PatchAuto = require('Module:PatchAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local CustomLeague = Class.new()
local CustomInjector = Class.new(Injector)

local _args
local _league

local OFFLINE = 'offline'
local ONLINE = 'online'

local GAME_REFORGED = 'wc3r'
local GAME_FROZEN_THRONE = 'tft'
local GAME_REIGN = 'roc'
local GAME_DEFAULT_SWITCH_DATE = '2020-01-01'

local GAMES = {
	[GAME_REFORGED] = 'Reforged',
	[GAME_FROZEN_THRONE] = 'The Frozen Throne',
	[GAME_REIGN] = 'Reing of Chaos',
}

local DUOS = '2v2'
local MODES = {
	team = {tier = 'Team', store = 'team'},
	[DUOS] = {tier = ' 2v2', store = '2v2'},
	default = {store = '1v1'},
}

local TIER_1 = 1
local TIER_2 = 2

local NON_BREAKING_SPACE = '&nbsp;'
local DASH = '&ndash;'

local ESL_ICON = '[[File:ESL 2019 icon.png|20x20px|link=|ESL]] '
local ESL_TIERS = {
	championship = '[[File:ESL Pro Tour Masters.png|20x20px|Championship]] Championship',
	challenger = '[[File:ESL Pro Tour Challenger.png|20x20px|Challenger]] Challenger',
	qualifier = '[[File:ESL Pro Tour Qualifier.png|20x20px|Qualifier]] Qualifier',
	['open cup'] = '[[File:ESL 2019 icon.png|20x20px|Open Cup]] Open Cup',
}

local TIER_MODE_TYPES = 'types'
local TIER_MODE_TIERS = 'tiers'
local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'

function CustomLeague.run(frame)
	local league = League(frame)
	_league = league
	_args = league.args

	_args.game = CustomLeague._determineGame()
	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype

	if not _args.prizepoolusd and not _args.localcurrency and _args.prizepool then
		_args.prizepoolusd = _args.prizepool
		_args.prizepool = nil
	end

	league.createWidgetInjector = CustomLeague.createWidgetInjector
	league.defineCustomPageVariables = CustomLeague.defineCustomPageVariables
	league.addToLpdb = CustomLeague.addToLpdb
	league.shouldStore = CustomLeague.shouldStore
	league.createLiquipediaTierDisplay = CustomLeague.createLiquipediaTierDisplay
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = {GAMES[_args.game] and ('[[' .. GAMES[_args.game] .. ']]') or nil}},
			Cell{name = 'Game version', content = {CustomLeague._displayGameVersion()}},
			Cell{name = 'Server', content = {CustomLeague:_getServer()}}
			}
	elseif id == 'liquipediatier' then
		table.insert(widgets, Cell{
			name = ESL_ICON .. 'Pro Tour Tier',
			content = {ESL_TIERS[(_args.eslprotier or ''):lower()]}
		})
	elseif id == 'dates' then
		if _args.starttime then
			local dateCells = {}
			if _args.sdate then
				table.insert(dateCells, Cell{name = 'Start Date', content = {CustomLeague._displayStartDateTime()}})
			elseif _args.date then
				table.insert(dateCells, Cell{name = 'Date', content = {CustomLeague._displayStartDateTime()}})
			end
			table.insert(dateCells, Cell{name = 'End Date', content = {_args.edate}})
			return dateCells
		end
	elseif id == 'customcontent' then
		--player breakdown
		local playerRaceBreakDown = CustomLeague._playerRaceBreakDown() or {}
		--make playerNumber available for commons category check
		_args.player_number = playerRaceBreakDown.playerNumber
		local playerNumber = _args.player_number or 0
		Variables.varDefine('player_number', playerNumber)
		if playerNumber > 0 or _args.team_number then
			table.insert(widgets, Title{name = 'Participants breakdown'})
		end

		if playerNumber > 0 then
			table.insert(widgets, Cell{name = 'Number of players', content = {playerNumber}})
			table.insert(widgets, Breakdown{content = playerRaceBreakDown.display, classes = {'infobox-center'}})
		end
		if _args.team_number then
			table.insert(widgets, Cell{name = 'Number of teams', content = {_args.team_number}})
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

function CustomLeague._displayStartDateTime()
	return Countdown._create{
		date = Variables.varDefault('tournament_starttimeraw'),
		finished = Variables.varDefault('tournament_finished'),
	}
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

function CustomLeague._displayGameVersion()
	local patch = Variables.varDefault('tournament_patch')
	local endPatch = Variables.varDefault('tournament_endpatch')
	local patchFeature = Variables.varDefault('tournament_patchfeature')

	if not patch then return end

	local gameVersion = '[[' .. patch .. '|' .. patch
	if patchFeature then
		gameVersion = gameVersion .. NON_BREAKING_SPACE .. patchFeature
	end
	gameVersion = gameVersion .. ']]'

	if patch == endPatch or not endPatch then
		return gameVersion
	end

	return gameVersion .. NON_BREAKING_SPACE .. DASH .. NON_BREAKING_SPACE
		.. '[[' .. endPatch .. '|' .. endPatch .. ']]'
end

function CustomLeague._getGameVersion()
	-- calculates patch data and sets several variables
	PatchAuto.infobox{
		patch = _args.patch,
		epatch = _args.epatch,
		patchFeature = (_args.patch_feature or ''):lower(),
		sDate = Variables.varDefault('tournament_startdate'),
		eDate = Variables.varDefault('tournament_enddate'),
		server = _args.server,
	}
end

function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage', 'false'))
end

function CustomLeague:_getServer()
	if String.isEmpty(_args.server) then
		return nil
	end

	return '[[Server|' .. _args.server .. ']]'
end

function CustomLeague._playerRaceBreakDown()
	local playerBreakDown = {}
	local playerNumber = tonumber(_args.player_number) or 0
	local humanNumber = tonumber(_args.human_number) or 0
	local orcNumber = tonumber(_args.orc_number) or 0
	local undeadNumber = tonumber(_args.undead_number) or 0
	local nightelfNumber = tonumber(_args.nightelf_number) or 0
	local randomNumber = tonumber(_args.random_number) or 0
	local multipleNumber = tonumber(_args.multiple_number) or 0

	if playerNumber == 0 then
		playerNumber = humanNumber + orcNumber + undeadNumber + undeadNumber + nightelfNumber + randomNumber + multipleNumber
	end

	if playerNumber > 0 then
		playerBreakDown.playerNumber = playerNumber
		if humanNumber + orcNumber + undeadNumber + nightelfNumber + randomNumber + multipleNumber > 0 then
			playerBreakDown.display = {}
			if humanNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'h', showLink = false, showTitle = false}
					.. ' ' .. humanNumber)
			end
			if orcNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'o', showLink = false, showTitle = false}
					.. ' ' .. orcNumber)
			end
			if undeadNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'u', showLink = false, showTitle = false}
					.. ' ' .. undeadNumber)
			end
			if nightelfNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'n', showLink = false, showTitle = false}
					.. ' ' .. nightelfNumber)
			end
			if randomNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'r', showLink = false, showTitle = false}
					.. ' ' .. randomNumber)
			end
			if multipleNumber > 0 then
				table.insert(playerBreakDown.display, Faction.Icon{faction = 'm', showLink = false, showTitle = false}
					.. ' ' .. multipleNumber)
			end
		end
	end

	return playerBreakDown or {}
end

function CustomLeague:defineCustomPageVariables()
	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', _args.tickername or name)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))
	Variables.varDefine('tournament_icon_filename', Variables.varDefault('tournament_icon'))
	Variables.varDefine('tournament_icon_name', (_args.abbreviation or ''):lower())

	Variables.varDefine('usd prize', Variables.varDefault('tournament_prizepoolusd'))
	Variables.varDefine('localcurrency', Variables.varDefault('tournament_currency'))
	Variables.varDefine('local prize', Variables.varDefault('tournament_prizepoollocal'))

	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tempdate', Variables.varDefault('tournament_enddate'))

	-- Warcraft specific stuff
	Variables.varDefine('environment', (_args.type or ''):lower() == OFFLINE and OFFLINE or ONLINE)

	if _args.starttime then
		Variables.varDefine('tournament_starttimeraw', Variables.varDefault('tournament_startdate', '') .. _args.starttime)

		local startTime = Variables.varDefault('tournament_startdate', '') .. ' '
			.. _args.starttime:gsub('<.*', '')

		Variables.varDefine('tournament_starttime', startTime)
		Variables.varDefine('start_time', startTime)
		local timeZone = _args.starttime:match('data-tz="(.*)"')
		if timeZone then
			Variables.varDefine('tournament_timezone', timeZone)
		end
	end

	Variables.varDefine('firstmatch', CustomLeague._getFirstMatchTime())

	--override var to standardize its entries
	Variables.varDefine('tournament_game', GAMES[_args.game])

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
		if data and type(data[1]) == 'table' then
			finished = true
		end
	end
	Variables.varDefine('tournament_finished', tostring(finished))

	--maps
	local maps = CustomLeague._getMaps('map')
	Variables.varDefine('tournament_maps', maps and Json.stringify(maps) or '')

	local seriesNumber = _args.number
	if Logic.isNumeric(seriesNumber) then
		Variables.varDefine('tournament_series_number', seriesNumber)
	end

	CustomLeague._getGameVersion()
end

function CustomLeague._getFirstMatchTime()
	local matchData = mw.ext.LiquipediaDB.lpdb('match', {
		conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
			.. 'AND [[dateexact::1]]',
		query = 'date',
		order = 'date asc',
		limit = 1
	})
	if matchData and type(matchData[1]) == 'table' then
		return matchData[1].date
	end
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
	lpdbData.game = GAMES[_args.game]
	lpdbData.patch = Variables.varDefault('tournament_patch')
	lpdbData.endpatch = Variables.varDefault('tournament_endpatch', Variables.varDefault('tournament_patch'))
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
	lpdbData.sortdate = Variables.varDefault('tournament_starttime')
		and (Variables.varDefault('tournament_starttime') .. (Variables.varDefault('tournament_timezone') or ''))
		or Variables.varDefault('firstmatch', Variables.varDefault('tournament_startdate'))
	lpdbData.publishertier = ESL_TIERS[(_args.eslprotier or ''):lower()] and _args.eslprotier:lower() or nil
	lpdbData.mode = CustomLeague._getMode()
	lpdbData.extradata.seriesnumber = Variables.varDefault('tournament_series_number')

	return lpdbData
end

function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function CustomLeague._determineGame()
	if _args.game and GAMES[_args.game:lower()] then
		return _args.game:lower()
	end

	local startDate = _league:_cleanDate(_args.sdate) or _league:_cleanDate(_args.date)
	if not startDate then
		return
	end

	if startDate > GAME_DEFAULT_SWITCH_DATE then
		return GAME_REFORGED
	end

	return GAME_FROZEN_THRONE
end

function CustomLeague:getWikiCategories()
	local categories = {}

	if String.isNotEmpty(_args.eslprotier) then
		table.insert(categories, 'ESL Pro Tour Tournaments')
	end

	if GAMES[_args.game] then
		table.insert(categories, GAMES[_args.game] .. ' Competitions')
	end

	if _args.mode == DUOS then
		table.insert(categories, '2v2 Tournaments')
	end

	local tier = tonumber(_args.liquipediatier)
	if tier == TIER_1 or tier == TIER_2 then
		table.insert(categories, 'Big Tournaments')
	else
		table.insert(categories, 'Small Tournaments')
	end

	local year = string.sub(Variables.varDefault('tournament_enddate', ''), 1, 4)
	if String.isNotEmpty(year) then
		table.insert(categories, 'Tournaments in ' .. year)
	end

	return categories
end

function CustomLeague:createLiquipediaTierDisplay(args)
	local tier = args.liquipediatier
	local tierType = args.liquipediatiertype
	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierString(tierString, tierMode)
		local tierText = self:_getTierText(tierString, tierMode)
		if not tierText then
			tierMode = tierMode == TIER_MODE_TYPES and 'Tiertype' or 'Tier'
			table.insert(
				self.warnings,
				String.interpolate(INVALID_TIER_WARNING, {tierString = tierString, tierMode = tierMode})
			)
			return ''
		else
			if self:shouldStore(args) then
				self.infobox:categories(tierText .. ' Tournaments')
			end
			local tierLink = tierText .. CustomLeague._getModeInTier() .. ' Tournaments'

			return '[[' .. tierLink .. '|' .. tierText .. ']]'
		end
	end

	local tierDisplay = buildTierString(tier, TIER_MODE_TIERS)

	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType, TIER_MODE_TYPES) .. '&nbsp;(' .. tierDisplay .. ')'
	end

	return tierDisplay .. CustomLeague._getModeDisplayInTier()
end

function CustomLeague._getMode()
	return (MODES[_args.mode] or {}).store or MODES.default.store
end

function CustomLeague._getModeInTier()
	local mode = (MODES[_args.mode] or {}).tier
	if mode then
		return ' ' .. mode
	end

	return ''
end

function CustomLeague._getModeDisplayInTier()
	local mode = (MODES[_args.mode] or {}).tier
	if mode then
		return ' (' .. mode .. ')'
	end

	return ''
end

return CustomLeague
