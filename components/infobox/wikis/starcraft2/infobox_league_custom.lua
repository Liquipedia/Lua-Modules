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
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local InfoboxPrizePool = Lua.import('Module:Infobox/Extensions/PrizePool')
local Injector = Lua.import('Module:Infobox/Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class Starcraft2LeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local CANCELLED = 'cancelled'
local FINISHED = 'finished'
local DEFAULT_MODE = '1v1'
local GREATER_EQUAL = '&#8805;'
local PRIZE_POOL_ROUND_PRECISION = 2
local TODAY = os.date('%Y-%m-%d', os.time())

local GAME_MOD = 'mod'
local GAME_LOTV = Game.toIdentifier{game = 'lotv'}

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.liquipediatiertype = league.args.liquipediatiertype or league.args.tiertype

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	args.raceBreakDown = RaceBreakdown.run(args) or {}
	args.player_number = args.raceBreakDown.total
	args.maps = self:_getMaps('map', args)
	args.number = tonumber(args.number)
	self.data.mode = args.mode or DEFAULT_MODE
	self.data.game = (args.game or ''):lower() == GAME_MOD and GAME_MOD or self.data.game
	self.data.publishertier = tostring(Logic.readBool(args.featured))
	self.data.status = self:_getStatus(args)

	self:_computeChronology(args)
	self:_computePatch(args)
end

---@param args table
function CustomLeague:_computePatch(args)
	local prefixPatch = function(patch)
		if not patch then return end
		return 'Patch ' .. patch
	end

	local shouldFetchPatch = Logic.nilOr(Logic.readBoolOrNil(args.autopatch), true)
	local fetchPatch = function(date)
		if not shouldFetchPatch or self.data.game ~= GAME_LOTV then return end
		return Autopatch._main{date}
	end

	local patch = args.patch or fetchPatch(self.data.startDate or TODAY)
	local endPatch = args.epatch or fetchPatch(self.data.endDate or TODAY) or patch

	self.data.patch = prefixPatch(patch)
	self.data.endPatch = prefixPatch(endPatch)
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

-- Automatically fill in next/previous for touranaments that are part of a series
---@param args table
function CustomLeague:_computeChronology(args)
	-- Criteria for automatic chronology are
	-- - part of a series and numbered
	-- - the subpage name matches the number
	-- - prev or next are unspecified
	-- - and not suppressed via auto_chronology=false
	local title = mw.title.getCurrentTitle()
	local number = tonumber(title.subpageText)
	local automateChronology = String.isNotEmpty(args.series)
		and number
		and args.number == number
		and title.subpageText ~= title.text
		and Logic.readBool(args.auto_chronology or true)
		and (String.isEmpty(args.next) or String.isEmpty(args.previous))

	if not automateChronology then
		return
	end

	local fromAutomated = function(shiftedNumber)
		local page = title.basePageTitle:subPageTitle(tostring(shiftedNumber)).fullText
		return Page.exists(page) and (page .. '|#' .. shiftedNumber) or nil
	end

	args.previous = Logic.emptyOr(args.previous, fromAutomated(number - 1))
	args.next = Logic.emptyOr(args.next, fromAutomated(number + 1))
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'gamesettings' then
		return {
			Cell{name = 'Game Version', content = {self.caller:_getGameVersion(args)}},
			Cell{name = 'Server', content = {self.caller:_getServer(args)}}
		}
	elseif id == 'customcontent' then
		if args.player_number and args.player_number > 0 or args.team_number then
			Array.appendWith(widgets,
				Title{name = 'Participants'},
				Cell{name = 'Number of Players', content = {args.raceBreakDown.total}},
				Cell{name = 'Number of Teams', content = {args.team_number}},
				Breakdown{content = args.raceBreakDown.display or {}, classes = { 'infobox-center' }}
			)
		end

		--maps
		---@param prefix string
		---@param defaultTitle string
		---@param maps {link: string, displayname: string}[]?
		local displayMaps = function(prefix, defaultTitle, maps)
			if String.isEmpty(args[prefix .. 1]) then return end
			Array.appendWith(widgets,
				Title{name = args[prefix .. 'title'] or defaultTitle},
				Center{content = self.caller:_mapsDisplay(maps or self.caller:_getMaps(prefix, args))}
			)
		end

		displayMaps('map', 'Maps', args.maps)
		displayMaps('2map', '2v2 Maps')
		displayMaps('3map', '3v3 Maps')
	end

	return widgets
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

---@param args table
---@return number|string?
function CustomLeague:displayPrizePool(args)
	if String.isEmpty(args.prizepool) and String.isEmpty(args.prizepoolusd) then
		return
	end

	local localCurrency = args.localcurrency

	if localCurrency == 'text' then
		return args.prizepool
	end

	local prizePoolUSD = args.prizepoolusd
	local prizePool = args.prizepool

	if not localCurrency and not prizePoolUSD then
		prizePoolUSD = prizePool
		prizePool = nil
	end

	local hasPlus
	prizePoolUSD, hasPlus = self:_removePlus(prizePoolUSD)
	prizePool, hasPlus = self:_removePlus(prizePool, hasPlus)

	return (hasPlus and (GREATER_EQUAL .. ' ') or '') .. InfoboxPrizePool.display{
		prizepool = prizePool,
		prizepoolusd = prizePoolUSD,
		currency = localCurrency,
		rate = args.currency_rate,
		date = Logic.emptyOr(args.currency_date, self.data.endDate),
		displayRoundPrecision = PRIZE_POOL_ROUND_PRECISION,
	}
end

---@param inputValue string?
---@param alreadyHasPlus boolean?
---@return string?
---@return boolean?
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

---@param args table
---@return string
function CustomLeague:_getGameVersion(args)
	local betaPrefix = String.isNotEmpty(args.beta) and 'Beta ' or ''

	local gameDisplay = self.data.game == GAME_MOD and (args.modname or 'Mod')
		or Page.makeInternalLink(Game.name{game = self.data.game})

	local patch = self.data.patch
	local endPatch = self.data.endPatch

	local patchDisplay = betaPrefix .. table.concat({
		Page.makeInternalLink(patch),
		Page.makeInternalLink(endPatch ~= patch and patch and endPatch or nil)
	}, ' &ndash; ')

	return table.concat({gameDisplay, patchDisplay}, '<br>')
end

---@param args table
---@return boolean
function CustomLeague:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(args.disable_lpdb) and
		not Logic.readBool(args.disable_storage) and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage', 'false'))
end

---@param args table
---@return string?
function CustomLeague:_getServer(args)
	if String.isEmpty(args.server) then
		return nil
	end
	local server = args.server
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

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	Variables.varDefine('headtohead', args.headtohead or 'true')
	Variables.varDefine('tournament_maps', Json.stringify(args.maps))
	Variables.varDefine('tournament_series_number', args.number and string.format('%05i', args.number) or nil)
end

---@param prefix string
---@param args table
---@return {link: string, displayname: string}[]
function CustomLeague:_getMaps(prefix, args)
	local mapArgs = self:getAllArgsForBase(args, prefix)

	return Table.map(mapArgs, function(mapIndex, map)
		local mapArray = mw.text.split(map, '|')
		return mapIndex, {
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(mapArray[1]),
			displayname = args[prefix .. mapIndex .. 'display'] or mapArray[#mapArray],
		}
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.maps = Json.stringify(args.maps)

	lpdbData.extradata.seriesnumber = args.number and string.format('%05i', args.number) or nil

	return lpdbData
end

---@param content string|Html|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	if self.data.game == GAME_MOD then
		return {}
	end

	local betaPrefix = String.isNotEmpty(args.beta) and 'Beta ' or ''
	return {betaPrefix .. Game.abbreviation{game = self.data.game} .. ' Competitions'}
end

---@param args table
---@return boolean
function CustomLeague:liquipediaTierHighlighted(args)
	return Logic.readBool(args.featured)
end

return CustomLeague
