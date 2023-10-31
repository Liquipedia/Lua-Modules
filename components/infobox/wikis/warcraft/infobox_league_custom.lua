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
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown', {requireDevIfEnabled = true})

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
	[GAME_REIGN] = 'Reign of Chaos',
}

local MODES = {
	team = {tier = 'Team', store = 'team', category = 'Team'},
	['2v2'] = {tier = ' 2v2', store = '2v2', category = '2v2'},
	default = {store = '1v1', category = 'Individual'},
}

local BREAKDOWN_RACES = Array.map(Array.map(Array.append(Faction.knownFactions, 'm'), Faction.toName), string.lower)

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

---@param frame Frame
---@return Html|string
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
	league.addParticipantTypeCategory = CustomLeague.addParticipantTypeCategory
	league.appendLiquipediatierDisplay = CustomLeague.appendLiquipediatierDisplay
	league.getWikiCategories = CustomLeague.getWikiCategories

	return league:createInfobox(frame)
end

---@return WidgetInjector
function CustomLeague:createWidgetInjector()
	return CustomInjector()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = {GAMES[_args.game] and ('[[' .. GAMES[_args.game] .. ']]') or nil}},
			Cell{name = 'Game version', content = {
				CustomLeague._displayGameVersion(),
				_args.patch2 and ('[[' .. _args.patch2 .. ']]') or nil
			}},
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
		local raceBreakdown = RaceBreakdown.run(_args, BREAKDOWN_RACES) or {}
		_args.player_number = _args.player_number or raceBreakdown.total

		if _args.player_number or _args.team_number then
			table.insert(widgets, Title{name = 'Participants breakdown'})
		end

		if _args.player_number then
			Array.appendWith(widgets,
				Cell{name = 'Number of Players', content = {_args.player_number or raceBreakdown.total}},
				Breakdown{content = raceBreakdown.display or {}, classes = { 'infobox-center' }}
			)

			_args.player_number = string.gsub(_args.player_number, '%+', '')
		end

		if _args.team_number then
			table.insert(widgets, Cell{name = 'Number of Teams',
				content = {CustomLeague._displayParticipantNumber(_args.team_number)}})

			-- clean var of '+' suffix
			_args.team_number = string.gsub(_args.team_number, '%+', '')
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

---@param number number|string
---@return string
function CustomLeague._displayParticipantNumber(number)
	local numberOfReplacements
	number, numberOfReplacements = string.gsub(number, '%+', '')

	if (tonumber(numberOfReplacements) or 0) > 0 then
		return tostring(mw.html.create()
			:node(mw.html.create('small'):wikitext('more than '))
			:wikitext(number))
	end

	return number
end

---@return string
function CustomLeague._displayStartDateTime()
	return Countdown._create{
		date = Variables.varDefault('tournament_starttimeraw'),
		finished = Variables.varDefault('tournament_finished'),
	}
end

---@param prefix string
---@return string[]
function CustomLeague._mapsDisplay(prefix)
	local maps = CustomLeague._getMaps(prefix)

	return {table.concat(
		Array.map(maps or {}, function(mapData)
			return tostring(CustomLeague:_createNoWrappingSpan(
				PageLink.makeInternalLink({}, mapData.displayname, mapData.link)
			))
		end),
		'&nbsp;• '
	)}
end

---@return string?
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

---@param args table
---@return boolean
function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage', 'false'))
end

---@return string?
---@return string?
function CustomLeague:_getServer()
	if String.isEmpty(_args.server) then
		return nil
	end

	if String.isEmpty(_args.server2) then
		return '[[Server|' .. _args.server .. ']]'
	end

	return '[[Server|' .. _args.server .. ']]', '[[Server|' .. _args.server2 .. ']]'
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', args.tickername or name)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))
	Variables.varDefine('tournament_icon_filename', Variables.varDefault('tournament_icon'))
	Variables.varDefine('tournament_icon_name', (args.abbreviation or ''):lower())

	Variables.varDefine('usd prize', Variables.varDefault('tournament_prizepoolusd'))
	Variables.varDefine('localcurrency', Variables.varDefault('tournament_currency'))
	Variables.varDefine('local prize', Variables.varDefault('tournament_prizepoollocal'))

	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tempdate', Variables.varDefault('tournament_enddate'))

	-- Warcraft specific stuff
	Variables.varDefine('environment', (args.type or ''):lower() == OFFLINE and OFFLINE or ONLINE)

	if args.starttime then
		Variables.varDefine('tournament_starttimeraw', Variables.varDefault('tournament_startdate', '') .. args.starttime)

		local startTime = Variables.varDefault('tournament_startdate', '') .. ' '
			.. args.starttime:gsub('<.*', '')

		Variables.varDefine('tournament_starttime', startTime)
		Variables.varDefine('start_time', startTime)
		local timeZone = args.starttime:match('data%-tz="(.-)"')
		if timeZone then
			Variables.varDefine('tournament_timezone', timeZone)
		end
	end

	Variables.varDefine('firstmatch', CustomLeague._getFirstMatchTime())

	--override var to standardize its entries
	Variables.varDefine('tournament_game', GAMES[args.game])

	--check if tournament is finished
	local finished = Logic.readBoolOrNil(args.finished)
	local queryDate = Variables.varDefault('tournament_enddate', '2999-99-99')
	if finished == nil and os.date('%Y-%m-%d') >= queryDate then
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
	Variables.varDefine('tournament_finished', tostring(finished or false))

	--maps
	local maps = CustomLeague._getMaps('map')
	Variables.varDefine('tournament_maps', maps and Json.stringify(maps) or '')

	local seriesNumber = args.number
	if Logic.isNumeric(seriesNumber) then
		Variables.varDefine('tournament_series_number', seriesNumber)
	end

	--publisher tier
	Variables.varDefine('tournament_publishertier',
		ESL_TIERS[(args.eslprotier or ''):lower()] and args.eslprotier:lower() or nil
	)

	CustomLeague._getGameVersion()
end

---@return string?
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

---@param prefix string
---@return {link: string, displayname: string}[]?
function CustomLeague._getMaps(prefix)
	if String.isEmpty(_args[prefix .. '1']) then
		return
	end
	local mapArgs = _league:getAllArgsForBase(_args, prefix)

	return Table.map(mapArgs, function(mapIndex, map)
		local splitMap = mw.text.split(map, '|')
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(splitMap[1]),
			displayname = _args[prefix .. mapIndex .. 'display'] or splitMap[#splitMap],
		}
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.game = GAMES[args.game]
	lpdbData.patch = Variables.varDefault('tournament_patch')
	lpdbData.endpatch = Variables.varDefault('tournament_endpatch', Variables.varDefault('tournament_patch'))
	local status = args.status
		or Logic.readBool(Variables.varDefault('cancelled tournament')) and 'cancelled'
		or Logic.readBool(Variables.varDefault('tournament_finished')) and 'finished'
	lpdbData.status = status
	lpdbData.maps = Variables.varDefault('tournament_maps')
	local participantsNumber = tonumber(args.team_number) or 0
	if participantsNumber == 0 then
		participantsNumber = tonumber(args.player_number) or 0
	end
	lpdbData.participantsnumber = participantsNumber
	lpdbData.sortdate = Variables.varDefault('tournament_starttime')
		and (Variables.varDefault('tournament_starttime') .. (Variables.varDefault('tournament_timezone') or ''))
		or Variables.varDefault('firstmatch', Variables.varDefault('tournament_startdate'))
	lpdbData.mode = CustomLeague._getMode()
	lpdbData.extradata.seriesnumber = Variables.varDefault('tournament_series_number')

	lpdbData.extradata.server2 = args.server2
	lpdbData.extradata.patch2 = args.patch2

	return lpdbData
end

---@param content string|Html|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

---@return string
function CustomLeague._determineGame()
	if _args.game and GAMES[_args.game:lower()] then
		return _args.game:lower()
	end

	local startDate = _league:_cleanDate(_args.sdate) or _league:_cleanDate(_args.date)

	if startDate and startDate > GAME_DEFAULT_SWITCH_DATE then
		return GAME_REFORGED
	end

	return GAME_FROZEN_THRONE
end

---@param args table
---@return string[]
function CustomLeague:addParticipantTypeCategory(args)
	return {(MODES[args.mode] or MODES.default).category .. ' Tournaments'}
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {'Tournaments'}

	if GAMES[args.game] then
		table.insert(categories, GAMES[args.game] .. ' Competitions')
	end

	if String.isNotEmpty(args.eslprotier) then
		table.insert(categories, 'ESL Pro Tour Tournaments')
	end

	local tier = tonumber(args.liquipediatier)
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

---@return string
function CustomLeague._getMode()
	return (MODES[_args.mode] or MODES.default).store
end

---@param args table
---@return string?
function CustomLeague:createLiquipediaTierDisplay(args)
	local tierDisplay = Tier.display(args.liquipediatier, args.liquipediatiertype, {link = true, mode = args.mode})

	if String.isEmpty(tierDisplay) then
		return
	end

	return tierDisplay .. self:appendLiquipediatierDisplay(args)
end

---@param args table
---@return string
function CustomLeague:appendLiquipediatierDisplay(args)
	local modeDisplay = (MODES[args.mode] or {}).tier
	if not modeDisplay then
		return ''
	end
	return NON_BREAKING_SPACE .. mw.getContentLanguage():ucfirst(modeDisplay)
end

return CustomLeague
