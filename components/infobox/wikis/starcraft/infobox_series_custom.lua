---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Json = require('Module:Json')
local Namespace = require('Module:Namespace')
local Series = require('Module:Infobox/Series')
local SeriesTotalPrize = require('Module:SeriesTotalPrize')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local _TIER_MODE_TYPES = 'types'
local _TIER_MODE_TIERS = 'tiers'

local CustomInjector = Class.new(Injector)

local CustomSeries = {}

local _args

function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args

	series.createWidgetInjector = CustomSeries.createWidgetInjector

	return series:createInfobox(frame)
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

function CustomInjector:parse(id, widgets)
	if id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {
					CustomSeries._createLiquipediaTierDisplay(
						_args.liquipediatier,
						_args.liquipediatiertype or _args.tiertype
					)
				}
			}
		}
	end

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
		_args.disable_smw == 'true' or
		_args.disable_lpdb == 'true' or
		_args.disable_storage == 'true'
	then
		Variables.varDefine('disable_SMW_storage', 'true')
	else
		--needed for e.g. External Cups Lists
		local name = _args.name or mw.title.getCurrentTitle().text
		Variables.varDefine('featured', _args.featured or '')
		Variables.varDefine('headtohead', _args.headtohead or '')
		Variables.varDefine('tournament_liquipediatier', _args.liquipediatier or '')
		Variables.varDefine('tournament_liquipediatiertype', _args.liquipediatiertype or _args.tiertype or '')
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

--function for custom tier handling
function CustomSeries:_createLiquipediaTierDisplay(tier, tierType)
	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierString(tierString, tierMode)
		local tierText
		if not Tier.text[tierMode] then -- allow legacy tier modules
			tierText = Tier.text[tierString]
		else -- default case, i.e. tier module with intended format
			tierText = Tier.text[tierMode][tierString:lower()]
		end
		if not tierText then
			tierMode = tierMode == _TIER_MODE_TYPES and 'Tiertype' or 'Tier'
			table.insert(
				self.warnings,
				String.interpolate(_INVALID_TIER_WARNING, {tierString = tierString, tierMode = tierMode})
			)
			return ''
		else
			self.infobox:categories(tierText .. ' Tournaments')
			return '[[' .. tierText .. ' Tournaments|' .. tierText .. ']]'
		end
	end

	local tierDisplay = buildTierString(tier, _TIER_MODE_TIERS)

	if String.isNotEmpty(tierType) then
		tierDisplay = buildTierString(tierType, _TIER_MODE_TYPES) .. '&nbsp;(' .. tierDisplay .. ')'
	end

	return tierDisplay .. self.appendLiquipediatierDisplay(args)
end

return CustomSeries
