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
local PageLink = require('Module:Page')
local PatchAuto = require('Module:PatchAuto')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local League = Lua.import('Module:Infobox/League/temp', {requireDevIfEnabled = true})
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftLeagueInfobox: InfoboxLeagueTemp
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local OFFLINE = 'offline'
local ONLINE = 'online'

local GAME_REFORGED = 'wc3r'
local GAME_FROZEN_THRONE = 'tft'
local GAME_DEFAULT_SWITCH_DATE = '2020-01-01'

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

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		return {
			Cell{name = 'Game', content = {Game.text{game = self.data.game}}},
			Cell{name = 'Game Version', content = {
				CustomLeague._displayGameVersion(),
				args.patch2 and ('[[' .. args.patch2 .. ']]') or nil
			}},
			Cell{name = 'Server', content = self.caller:_getServers(args)}
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
				table.insert(dateCells, Cell{name = 'Start Date', content = {CustomLeague._displayStartDateTime()}})
			elseif args.date then
				table.insert(dateCells, Cell{name = 'Date', content = {CustomLeague._displayStartDateTime()}})
			end
			table.insert(dateCells, Cell{name = 'End Date', content = {args.edate}})
			return dateCells
		end
	elseif id == 'customcontent' then
		local raceBreakdown = RaceBreakdown.run(args, BREAKDOWN_RACES) or {}
		args.player_number = args.player_number or raceBreakdown.total

		if args.player_number or args.team_number then
			table.insert(widgets, Title{name = 'Participants breakdown'})
		end

		if args.player_number then
			Array.appendWith(widgets,
				Cell{name = 'Number of Players', content = {args.player_number or raceBreakdown.total}},
				Breakdown{content = raceBreakdown.display or {}, classes = { 'infobox-center' }}
			)

			args.player_number = string.gsub(args.player_number, '%+', '')
		end

		if args.team_number then
			table.insert(widgets, Cell{name = 'Number of Teams',
				content = {CustomLeague._displayParticipantNumber(args.team_number)}})

			-- clean var of '+' suffix
			args.team_number = string.gsub(args.team_number, '%+', '')
		end

		--maps
		if String.isNotEmpty(args.map1) then
			table.insert(widgets, Title{name = args['maptitle'] or 'Maps'})
			table.insert(widgets, Center{content = self.caller:_mapsDisplay('map')})
		end

		if String.isNotEmpty(args['2map1']) then
			table.insert(widgets, Title{name = args['2maptitle'] or '2v2 Maps'})
			table.insert(widgets, Center{content = self.caller:_mapsDisplay('2map')})
		end

		if String.isNotEmpty(args['3map1']) then
			table.insert(widgets, Title{name = args['3maptitle'] or '3v3 Maps'})
			table.insert(widgets, Center{content = self.caller:_mapsDisplay('3map')})
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
function CustomLeague:_mapsDisplay(prefix)
	local maps = self:_getMaps(prefix)

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

function CustomLeague:_getGameVersion()
	local args = self.args
	-- calculates patch data and sets several variables
	PatchAuto.infobox{
		patch = args.patch,
		epatch = args.epatch,
		patchFeature = (args.patch_feature or ''):lower(),
		sDate = self.data.startDate,
		eDate = self.data.endDate,
		server = args.server,
	}
end

---@param args table
---@return table
function CustomLeague:_getServers(args)
	return Array.map(self:getAllArgsForBase(args, 'server'), function(server) return '[[Server|'.. server ..']]' end)
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

	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
	Variables.varDefine('tempdate', self.data.endDate)

	-- Warcraft specific stuff
	Variables.varDefine('environment', (args.type or ''):lower() == OFFLINE and OFFLINE or ONLINE)

	if args.starttime then
		Variables.varDefine('tournament_starttimeraw', (self.data.startDate or '') .. args.starttime)

		local startTime = (self.data.startDate or '') .. ' '
			.. args.starttime:gsub('<.*', '')

		Variables.varDefine('tournament_starttime', startTime)
		Variables.varDefine('start_time', startTime)
		local timeZone = args.starttime:match('data%-tz="(.-)"')
		if timeZone then
			Variables.varDefine('tournament_timezone', timeZone)
		end
	end

	Variables.varDefine('firstmatch', CustomLeague._getFirstMatchTime())

	--check if tournament is finished
	local finished = Logic.readBoolOrNil(args.finished)
	local queryDate = self.data.endDate
	if finished == nil and queryDate and os.date('%Y-%m-%d') >= queryDate then
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
	local maps = self:_getMaps('map')
	Variables.varDefine('tournament_maps', maps and Json.stringify(maps) or '')

	local seriesNumber = args.number
	if Logic.isNumeric(seriesNumber) then
		Variables.varDefine('tournament_series_number', seriesNumber)
	end

	--publisher tier
	Variables.varDefine('tournament_publishertier',
		ESL_TIERS[(args.eslprotier or ''):lower()] and args.eslprotier:lower() or nil
	)

	self:_getGameVersion()
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
function CustomLeague:_getMaps(prefix)
	local args = self.args
	if String.isEmpty(args[prefix .. '1']) then
		return
	end
	local mapArgs = self:getAllArgsForBase(self.args, prefix)

	local maps = Table.map(mapArgs, function(mapIndex, map)
		local splitMap = mw.text.split(map, '|')

		splitMap[1] = (MapsData[splitMap[1]:lower()] or {}).name or splitMap[1]

		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(splitMap[1]),
			displayname = args[prefix .. mapIndex .. 'display'] or splitMap[#splitMap],
		}
	end)

	Array.sortInPlaceBy(maps, Operator.property('link'))

	return maps
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
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
		or Variables.varDefault('firstmatch', self.data.startDate)
	lpdbData.mode = self:_getMode()
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

---@param args table
---@return string[]
function CustomLeague:addParticipantTypeCategory(args)
	return {(MODES[args.mode] or MODES.default).category .. ' Tournaments'}
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	local categories = {'Tournaments'}

	local game = Game.name{game = self.data.game}
	if game then
		table.insert(categories, game .. ' Competitions')
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
