---
-- @Liquipedia
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local SeriesTotalPrize = Lua.import('Module:SeriesTotalPrize')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')
local Variables = Lua.import('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Series = Lua.import('Module:Infobox/Series')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local CustomInjector = Class.new(Injector)

---@class StarcraftSeriesInfobox: SeriesInfobox
local CustomSeries = Class.new(Series)

---@param frame Frame
---@return string
function CustomSeries.run(frame)
	local series = CustomSeries(frame)
	series:setWidgetInjector(CustomInjector(series))

	series.args.liquipediatiertype = series.args.liquipediatiertype or series.args.tiertype
	series.args.liquipediatier = series.args.liquipediatier or series.args.tier

	series:_addCustomVariables()

	return series:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'totalprizepool' then
		if Logic.readBoolOrNil(args.prizepooltot) == false then return {} end
		return {
			Cell{name = 'Cumulative Prize Pool', content = {self.caller:_displaySeriesPrizepools()}},
		}
	elseif id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Patch', content = {self.caller:_getPatch()}},
			Cell{name = 'Server', content = {args.server}},
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Format', content = {args.format}}
		)
	end

	return widgets
end

---@return string?
function CustomSeries:_displaySeriesPrizepools()
	local args = self.args
	local seriesTotalPrizeInput = Json.parseIfString(args.prizepooltot or '{}')
	local series = seriesTotalPrizeInput.series or args.series or self.pagename

	return SeriesTotalPrize._get{
		series = series,
		limit = seriesTotalPrizeInput.limit or args.limit,
		offset = seriesTotalPrizeInput.offset or args.offset,
		external = seriesTotalPrizeInput.external or args.external,
		onlytotal = seriesTotalPrizeInput.onlytotal or args.onlytotal,
	}
end

---@return string?
function CustomSeries:_getPatch()
	local patch = self.args.patch
	local endPatch = self.args.epatch
	if String.isEmpty(patch) then
		return nil
	end

	Variables.varDefine('patch', patch)
	Variables.varDefine('epatch', String.isNotEmpty(endPatch) and endPatch or patch)

	if String.isEmpty(endPatch) then
		return '[[' .. patch .. ']]'
	else
		return '[[' .. patch .. ']] &ndash; [[' .. endPatch .. ']]'
	end
end

function CustomSeries:_addCustomVariables()
	local args = self.args

	if
		(not Namespace.isMain()) or
		Logic.readBool(args.disable_smw) or
		Logic.readBool(args.disable_lpdb) or
		Logic.readBool(args.disable_storage)
	then
		Variables.varDefine('disable_LPDB_storage', 'true')
	else
		--needed for e.g. External Cups Lists
		local name = args.name or self.pagename
		Variables.varDefine('featured', args.featured or '')
		Variables.varDefine('headtohead', args.headtohead or '')
		local tier, tierType = Tier.toValue(args.liquipediatier, args.liquipediatiertype)
		Variables.varDefine('tournament_liquipediatier', tier or '')
		Variables.varDefine('tournament_liquipediatiertype', tierType or '')
		Variables.varDefine('tournament_mode', args.mode or '1v1')
		Variables.varDefine('tournament_ticker_name', args.tickername or name)
		Variables.varDefine('tournament_shortname', args.shortname or '')
		Variables.varDefine('tournament_name', name)
		Variables.varDefine('tournament_abbreviation', args.abbreviation or args.shortname or '')
		Variables.varDefine('tournament_game', args.game or '')
		Variables.varDefine('tournament_type', args.type or '')
		CustomSeries._setDateMatchVar(args.date, args.edate, args.sdate)
	end
end

---@param lpdbData table
---@param args table
---@return table
function CustomSeries:addToLpdb(lpdbData, args)
	Variables.varDefine('tournament_icon', lpdbData.icon)
	Variables.varDefine('tournament_icon_dark', lpdbData.icondark)
	return lpdbData
end

---@param date string?
---@param edate string?
---@param sdate string?
function CustomSeries._setDateMatchVar(date, edate, sdate)
	local endDate = CustomSeries._validDateOr(date, edate, sdate) or ''
	local startDate = CustomSeries._validDateOr(date, sdate, edate) or ''

	Variables.varDefine('tournament_enddate', endDate)
	Variables.varDefine('tournament_startdate', startDate)
end

---@param ... string
---@return string?
function CustomSeries._validDateOr(...)
	local regexString = '%d%d%d%d%-%d%d%-%d%d' --(i.e. YYYY-MM-DD)

	for _, input in Table.iter.spairs({...}) do
		local dateString = string.match(input, regexString)
		if dateString then
			return dateString
		end
	end
end

return CustomSeries
