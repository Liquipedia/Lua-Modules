---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local SeriesTotalPrize = require('Module:SeriesTotalPrize')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Series = Lua.import('Module:Infobox/Series', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Builder = Widgets.Builder

local CustomInjector = Class.new(Injector)

local CustomSeries = {}

local _args

function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args

	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype
	_args.liquipediatier = _args.liquipediatier or _args.tier

	series.createWidgetInjector = CustomSeries.createWidgetInjector

	return series:createInfobox()
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Patch', content = {CustomSeries._getPatch()}})
	table.insert(widgets, Cell{name = 'Server', content = {_args.server}})
	table.insert(widgets, Cell{name = 'Type', content = {_args.type}})
	table.insert(widgets, Cell{name = 'Format', content = {_args.format}})
	table.insert(widgets, Builder({
		builder = function()
			if _args.prizepooltot ~= 'false' then
				return {
					Cell{
						name = 'Total prize money',
						content = {CustomSeries._getSeriesPrizepools()}
					}
				}
			end
		end
	}))

	CustomSeries._addCustomVariables()

	return widgets
end

function CustomSeries._getSeriesPrizepools()
	local seriesTotalPrizeInput = Json.parseIfString(_args.prizepooltot or '{}')
	local series = seriesTotalPrizeInput.series or _args.series or mw.title.getCurrentTitle().text

	return SeriesTotalPrize._get{
		series = series,
		limit = seriesTotalPrizeInput.limit or _args.limit,
		offset = seriesTotalPrizeInput.offset or _args.offset,
		external = seriesTotalPrizeInput.external or _args.external,
		onlytotal = seriesTotalPrizeInput.onlytotal or _args.onlytotal,
	}
end

function CustomSeries._getPatch()
	local patch = _args.patch
	local endPatch = _args.epatch
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

function CustomSeries._addCustomVariables()
	if
		(not Namespace.isMain()) or
		Logic.readBool(_args.disable_smw) or
		Logic.readBool(_args.disable_lpdb) or
		Logic.readBool(_args.disable_storage)
	then
		Variables.varDefine('disable_LPDB_storage', 'true')
	else
		--needed for e.g. External Cups Lists
		local name = _args.name or mw.title.getCurrentTitle().text
		Variables.varDefine('featured', _args.featured or '')
		Variables.varDefine('headtohead', _args.headtohead or '')
		local tier, tierType = Tier.toValue(_args.liquipediatier, _args.liquipediatiertype)
		Variables.varDefine('tournament_liquipediatier', tier or '')
		Variables.varDefine('tournament_liquipediatiertype', tierType or '')
		Variables.varDefine('tournament_mode', _args.mode or '1v1')
		Variables.varDefine('tournament_ticker_name', _args.tickername or name)
		Variables.varDefine('tournament_shortname', _args.shortname or '')
		Variables.varDefine('tournament_name', name)
		Variables.varDefine('tournament_abbreviation', _args.abbreviation or _args.shortname or '')
		Variables.varDefine('tournament_game', _args.game or '')
		Variables.varDefine('tournament_type', _args.type or '')
		CustomSeries._setDateMatchVar(_args.date, _args.edate, _args.sdate)
	end
end

function Series:addToLpdb(lpdbData)
	Variables.varDefine('tournament_icon', lpdbData.icon)
	Variables.varDefine('tournament_icon_dark', lpdbData.icondark)
	return lpdbData
end

function CustomSeries._setDateMatchVar(date, edate, sdate)
	local endDate = CustomSeries._validDateOr(date, edate, sdate) or ''
	local startDate = CustomSeries._validDateOr(date, sdate, edate) or ''

	Variables.varDefine('date', endDate)
	Variables.varDefine('tournament_enddate', endDate)
	Variables.varDefine('tournament_startdate', startDate)
end

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
