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
local Game = require('Module:Game')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MapsData = mw.loadData('Module:Maps/data')
local Operator = require('Module:Operator')
local Page = require('Module:Page')
local PatchAuto = require('Module:PatchAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local CANCELLED = 'cancelled'
local FINISHED = 'finished'

local OFFLINE = 'offline'
local ONLINE = 'online'

local GAME_REFORGED = 'wc3r'
local GAME_FROZEN_THRONE = 'tft'
local GAME_DEFAULT_SWITCH_DATE = '2020-01-01'

local MODES = {
	team = {tier = 'Team', store = 'team', category = 'Team'},
	['FFA'] = {tier = ' FFA', store = 'FFA', category = 'FFA'},
	['4v4'] = {tier = ' 4v4', store = '4v4', category = '4v4'},
	['3v3'] = {tier = ' 3v3', store = '3v3', category = '3v3'},
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
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	local args = league.args

	args.liquipediatiertype = args.liquipediatiertype or args.tiertype

	if not args.prizepoolusd and not args.localcurrency and args.prizepool then
		args.prizepoolusd = args.prizepool
		args.prizepool = nil
	end

	return league:createInfobox(frame)
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.game = self:_determineGame(args.game)
	self.data.status = self:_getStatus(args)
	self.data.publishertier = ESL_TIERS[(args.eslprotier or ''):lower()] and args.eslprotier:lower() or nil
	self.data.raceBreakDown = RaceBreakdown.run(args, BREAKDOWN_RACES) or {}
	self.data.maps = self:_getMaps('map', args)
	self.data.number = tonumber(args.number)
	self.data.playerNumberDisplay = args.player_number or self.data.raceBreakDown.total

	args.player_number = string.gsub(self.data.playerNumberDisplay or 0, '%+', '')

	--this sets the below used wiki vars
	PatchAuto.infobox{
		patch = args.patch,
		epatch = args.epatch,
		patchFeature = (args.patch_feature or ''):lower(),
		sDate = self.data.startDate,
		eDate = self.data.endDate,
		server = args.server,
	}
	self.data.patch = Variables.varDefault('tournament_patch')
	self.data.endPatch = Variables.varDefault('tournament_endpatch', self.data.patch)
	self.data.patchFeature = Variables.varDefault('tournament_patchfeature')

	self.data.startTime = args.starttime and {
		raw = (self.data.startDate or '') .. args.starttime,
		startTime = (self.data.startDate or '') .. ' ' .. args.starttime:gsub('<.*', ''),
		timeZone = args.starttime:match('data%-tz="(.-)"'),
	} or {}

	self.data.firstMatch = CustomLeague._getFirstMatchTime()
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	Variables.varDefine('tournament_ticker_name', args.tickername or self.name)
	Variables.varDefine('tournament_tier', self.data.liquipediatier)
	Variables.varDefine('tournament_icon_filename', self.data.icon)
	Variables.varDefine('tournament_icon_name', (args.abbreviation or ''):lower())

	Variables.varDefine('usd prize', self.data.prizepoolUsd)
	Variables.varDefine('localcurrency', self.data.localCurrency)
	Variables.varDefine('local prize', Variables.varDefault('tournament_prizepoollocal'))

	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
	Variables.varDefine('tempdate', self.data.endDate)

	-- Warcraft specific stuff
	Variables.varDefine('environment', (args.type or ''):lower() == OFFLINE and OFFLINE or ONLINE)

	Variables.varDefine('tournament_starttimeraw', self.data.startTime.raw)
	Variables.varDefine('tournament_starttime', self.data.startTime.startTime)
	Variables.varDefine('start_time', self.data.startTime.startTime)
	Variables.varDefine('tournament_timezone', self.data.startTime.timeZone)

	Variables.varDefine('firstmatch', self.data.firstMatch)
	Variables.varDefine('tournament_finished', tostring(self.data.isFinished or false))
	Variables.varDefine('tournament_maps', Json.stringify(self.data.maps))
	Variables.varDefine('tournament_series_number', self.data.number)
end

---@param prefix string
---@param args table
---@return {link: string, displayname: string}[]
function CustomLeague:_getMaps(prefix, args)
	local maps = Table.map(self:getAllArgsForBase(args, prefix), function(mapIndex, map)
		local mapArray = mw.text.split(map, '|')

		mapArray[1] = (MapsData[mapArray[1]:lower()] or {}).name or mapArray[1]

		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(mapArray[1]),
			displayname = args[prefix .. mapIndex .. 'display'] or mapArray[#mapArray],
		}
	end)

	Array.sortInPlaceBy(maps, Operator.property('link'))

	return maps
end

---@param game string?
---@return string?
function CustomLeague:_determineGame(game)
	game = Game.toIdentifier{game = game}
	if game then return game end

	local startDate = self.data.startDate or self.data.endDate

	if startDate and startDate > GAME_DEFAULT_SWITCH_DATE then
		return Game.toIdentifier{game = GAME_REFORGED}
	end

	return Game.toIdentifier{game = GAME_FROZEN_THRONE}
end

---@param args table
---@return string?
function CustomLeague:_getStatus(args)
	local status = args.status or Variables.varDefault('tournament_status')
	if Logic.isNotEmpty(status) then
		---@cast status -nil
		return status:lower()
	end

	if Logic.readBool(args.cancelled or Variables.varDefault('cancelled tournament')) then
		return CANCELLED
	end

	if self:_isFinished(args) then
		self.data.isFinished = true
		return FINISHED
	end
end

---@param args table
---@return boolean
function CustomLeague:_isFinished(args)
	local finished = Logic.readBoolOrNil(args.finished)
	if finished ~= nil then
		return finished
	end

	local queryDate = self.data.endDate or self.data.startDate

	if not queryDate or os.date('%Y-%m-%d') < queryDate then
		return false
	end

	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']] '
			.. 'AND [[opponentname::!TBD]] AND [[placement::1]]',
		query = 'date',
		order = 'date asc',
		limit = 1
	})[1] ~= nil
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = {Game.text{game = caller.data.game}}},
			Cell{name = 'Game Version', content = {
				caller:_displayGameVersion(),
				args.patch2 and ('[[' .. args.patch2 .. ']]') or nil
			}},
			Cell{name = 'Server', content = caller:_getServers(args)}
			}
	elseif id == 'liquipediatier' then
		table.insert(widgets, Cell{
			name = ESL_ICON .. 'Pro Tour Tier',
			content = {ESL_TIERS[(args.eslprotier or ''):lower()]}
		})
	elseif id == 'dates' then
		if args.starttime then
			local dateCells = {}
			if args.sdate then
				table.insert(dateCells, Cell{name = 'Start Date', content = {caller:_displayStartDateTime()}})
			elseif args.date then
				table.insert(dateCells, Cell{name = 'Date', content = {caller:_displayStartDateTime()}})
			end
			table.insert(dateCells, Cell{name = 'End Date', content = {args.edate}})
			return dateCells
		end
	elseif id == 'customcontent' then
		local playerNumber = caller.data.playerNumberDisplay
		if playerNumber or args.team_number then
			table.insert(widgets, Title{name = 'Participants breakdown'})
		end

		if playerNumber then
			Array.appendWith(widgets,
				Cell{name = 'Number of Players', content = {playerNumber}},
				Breakdown{content = caller.data.raceBreakDown.display or {}, classes = { 'infobox-center' }}
			)
		end

		if args.team_number then
			table.insert(widgets, Cell{name = 'Number of Teams',
				content = {CustomLeague._displayParticipantNumber(args.team_number)}})

			-- clean var of '+' suffix
			args.team_number = string.gsub(args.team_number, '%+', '')
		end

		--maps
		---@param prefix string
		---@param defaultTitle string
		---@param maps {link: string, displayname: string}[]?
		local displayMaps = function(prefix, defaultTitle, maps)
			if String.isEmpty(args[prefix .. 1]) then return end
			Array.appendWith(widgets,
				Title{name = args[prefix .. 'title'] or defaultTitle},
				Center{content = caller:_mapsDisplay(maps or caller:_getMaps(prefix, args))}
			)
		end

		displayMaps('map', 'Maps', caller.data.maps)
		displayMaps('2map', '2v2 Maps')
		displayMaps('3map', '3v3 Maps')
		displayMaps('4map', '4v4 Maps')
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
function CustomLeague:_displayStartDateTime()
	return Countdown._create{
		date = self.data.startTime.raw,
		finished = self.data.isFinished,
	}
end

---@param maps {link: string, displayname: string}[]
---@return string[]
function CustomLeague:_mapsDisplay(maps)
	return {table.concat(
		Array.map(maps, function(mapData)
			return tostring(self:_createNoWrappingSpan(
				Page.makeInternalLink({}, mapData.displayname, mapData.link)
			))
		end),
		'&nbsp;• '
	)}
end

---@return string?
function CustomLeague:_displayGameVersion()
	local patch = self.data.patch
	local endPatch = self.data.endPatch
	local patchFeature = self.data.patchFeature

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

---@param args table
---@return table
function CustomLeague:_getServers(args)
	return Array.map(self:getAllArgsForBase(args, 'server'), function(server) return '[[Server|'.. server ..']]' end)
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

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.patch = self.data.patch
	lpdbData.endpatch = self.data.endPatch
	lpdbData.maps = self.data.maps
	local participantsNumber = tonumber(args.team_number) or 0
	if participantsNumber == 0 then
		participantsNumber = tonumber(args.player_number) or 0
	end
	lpdbData.participantsnumber = participantsNumber
	lpdbData.sortdate = self.data.startTime.startTime
		and (self.data.startTime.startTime .. (self.data.startTime.timeZone or ''))
		or self.data.firstMatch or self.data.startDate
	lpdbData.mode = self:_getMode()
	lpdbData.extradata.seriesnumber = self.data.number

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

---@param args table
---@return string[]
function CustomLeague:addParticipantTypeCategory(args)
	return {(MODES[args.mode] or MODES.default).category .. ' Tournaments'}
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local tier = tonumber(args.liquipediatier)

	local categories = {
		'Tournaments',
		(tier == TIER_1 or tier == TIER_2) and 'Big Tournaments' or 'Small Tournaments'
	}

	local game = Game.name{game = self.data.game}
	if game then
		table.insert(categories, game .. ' Competitions')
	end

	if String.isNotEmpty(args.eslprotier) then
		table.insert(categories, 'ESL Pro Tour Tournaments')
	end

	local year = string.sub(self.data.endDate or '', 1, 4)
	if String.isNotEmpty(year) then
		table.insert(categories, 'Tournaments in ' .. year)
	end

	return categories
end

---@return string
function CustomLeague:_getMode()
	return (MODES[self.args.mode] or MODES.default).store
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
