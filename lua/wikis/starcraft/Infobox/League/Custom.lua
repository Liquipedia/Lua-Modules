---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')

local Widgets = Lua.import('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class StarcraftLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local CANCELLED = 'cancelled'
local FINISHED = 'finished'
local DEFAULT_MODE = '1v1'

---@param frame Frame
---@return Html
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	return league:createInfobox()
end

---@param args table
function CustomLeague:customParseArguments(args)
	self.data.raceBreakDown = RaceBreakdown.run(args) or {}
	self.data.maps = self:_getMaps('map', args)
	self.data.number = tonumber(args.number)
	self.data.mode = args.mode or DEFAULT_MODE
	self.data.status = self:_getStatus(args)

	args.player_number = self.data.raceBreakDown.total

	self:_computeChronology(args)
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
		and self.data.number == number
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
		table.insert(widgets, Cell{name = 'Patch', content = {CustomLeague._getPatch(args)}})
	elseif id == 'customcontent' then
		if args.player_number and args.player_number > 0 or args.team_number then
			Array.appendWith(widgets,
				Title{children = 'Participants'},
				Cell{name = 'Number of Players', content = {self.caller.data.raceBreakDown.total}},
				Cell{name = 'Number of Teams', content = {args.team_number}},
				Breakdown{children = self.caller.data.raceBreakDown.display or {}, classes = { 'infobox-center' }}
			)
		end

		--maps
		---@param prefix string
		---@param defaultTitle string
		---@param maps {link: string, displayname: string}[]?
		local displayMaps = function(prefix, defaultTitle, maps)
			if String.isEmpty(args[prefix .. 1]) then return end
			Array.appendWith(widgets,
				Title{children = args[prefix .. 'title'] or defaultTitle},
				Center{children = self.caller:_mapsDisplay(maps or self.caller:_getMaps(prefix, args))}
			)
		end

		displayMaps('map', 'Maps', self.caller.data.maps)
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

---@param content string|Html|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

---@param args table
---@return string
function CustomLeague._getPatch(args)
	return table.concat({
		Page.makeInternalLink(args.patch),
		Page.makeInternalLink(args.epatch ~= args.patch and args.patch and args.epatch or nil)
	}, ' &ndash; ')
end

---@param args table
function CustomLeague:defineCustomPageVariables(args)
	--Legacy vars
	local name = self.name
	Variables.varDefine('tournament_ticker_name', args.tickername or name)
	Variables.varDefine('tournament_abbreviation', args.abbreviation or '')
	Variables.varDefine('tournament_tier', self.data.liquipediatier)

	--Legacy date vars
	Variables.varDefine('date', self.data.endDate)
	Variables.varDefine('sdate', self.data.startDate)
	Variables.varDefine('edate', self.data.endDate)
	Variables.varDefine('formatted_tournament_date', self.data.startDate)
	Variables.varDefine('formatted_tournament_edate', self.data.endDate)
	Variables.varDefine('prizepooldate', self.data.endDate)
	Variables.varDefine('lpdbtime', mw.getContentLanguage():formatDate('U', self.data.endDate))

	--SC specific vars
	Variables.varDefine('headtohead', args.headtohead or 'true')
	Variables.varDefine('tournament_series_number', self.data.number and string.format('%05i', self.data.number) or nil)
	-- do not resolve redirect on the series input
	-- BW wiki has several series that are displayed on the same page
	-- hence they need to not RR them
	Variables.varDefine('tournament_series', args.series)
end

---@param lpdbData table
---@param args table
---@return table
function CustomLeague:addToLpdb(lpdbData, args)
	lpdbData.tickername = lpdbData.tickername or lpdbData.name
	lpdbData.maps = self:_concatArgs('map')
	-- do not resolve redirect on the series input
	-- BW wiki has several series that are displayed on the same page
	-- hence they need to not RR them
	lpdbData.series = args.series

	lpdbData.extradata.female = Logic.readBool(args.female) or nil

	return lpdbData
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {Logic.readBool(args.female) and 'Female Tournaments' or nil}
end

---@param base string
---@return string
function CustomLeague:_concatArgs(base)
	return table.concat(
		Array.map(self:getAllArgsForBase(self.args, base), mw.ext.TeamLiquidIntegration.resolve_redirect),
		';'
	)
end

return CustomLeague
