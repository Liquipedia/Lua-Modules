---
-- @Liquipedia
-- wiki=smash
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Series = require('Module:Infobox/Series')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')
local Logic = require('Module:Namespace')
local Namespace = require('Module:Namespace')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')


local CustomInjector = Class.new(Injector)

local CustomSeries = {}

local _series

function CustomSeries.run(frame)
	_series = Series(frame)

	_series.createWidgetInjector = CustomSeries.createWidgetInjector
	_series.addToLpdb = CustomSeries.addToLpdb

	_series.args.game = _series.args.game or 'none'

	return _series:createInfobox(frame)
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Format',
		content = {_series.args.format}
	}))
	CustomSeries._addCustomVariables(_series.args)
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia tier',
				content = {
					CustomSeries._createTier(
						_series.args.liquipediatier, (_series.args.liquipediatiertype))
				}

			}
		}
	elseif id == 'type' then
		return {
			Cell{
				name = 'Type',
				content = { mw.language.getContentLanguage():ucfirst(_series.args.type or '') }
		}}
	end

	return widgets
end


function CustomSeries._addCustomVariables(args)
	if not Namespace.isMain() or
		Logic.readBool(args.disable_smw) or
		Logic.readBool(args.disable_lpdb) or
		Logic.readBool(args.disable_storage)
	then
		Variables.VarDefine('disable_SMW_storage', 'true')

	else
		--needed for e.g. External Cups Lists
		local name = args.name or mw.title.getCurrentTitle().text
		Variables.VarDefine('featured', args.featured or '')
		Variables.VarDefine('headtohead', args.headtohead or '')
		Variables.VarDefine('tournament_tier', args.liquipediatier or '')
		Variables.VarDefine('tournament_tiertype', args.liquipediatiertype or args.tiertype or '')
		Variables.VarDefine('tournament_mode', args.mode or '1v1')
		Variables.VarDefine('tournament_ticker_name', args.tickername or name)
		Variables.VarDefine('tournament_shortname', args.shortname or '')
		Variables.VarDefine('tournament_name', name)
		Variables.VarDefine('tournament_abbreviation', args.abbreviation or args.shortname or '')
		Variables.VarDefine('tournament_game', args.game or '')
		Variables.VarDefine('tournament_type', args.type or '')
		Variables.varDefine('tournament_icon', args.icon)
		Variables.varDefine('tournament_icon_dark', args.icondark)
		CustomSeries._setDateMatchVar(args.date, args.edate, args.sdate)
	end
end

function CustomSeries:addToLpdb(lpdbData)
	lpdbData.extradata = {
		leagueiconsmall = _series.args.leagueiconsmall
	}

	return lpdbData
end

function CustomSeries._setDateMatchVar(date, edate, sdate)
	date = string.match(date or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(edate or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(sdate or '', '%d%d%d%d%-%d%d%-%d%d') or ''
	sdate = string.match(date or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(sdate or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(edate or '', '%d%d%d%d%-%d%d%-%d%d') or ''

	Variables.VarDefine('date', date)
	Variables.VarDefine('tournament_enddate', date)
	Variables.VarDefine('tournament_startdate', sdate)
end

function CustomSeries._createTier(tier, tierType)
	if String.isEmpty(tier) then
		return nil
	end

	local tierText = Tier['text'][tier]
	local hasInvalidTier = tierText == nil
	tierText = tierText or tier

	local hasTierType = tierType ~= nil and tierType ~= ''
	local hasInvalidTierType = false

	local output = '[[' .. tierText .. ' Tournaments|'

	if hasTierType then
		tierType = Tier['types'][string.lower(tierType or '')] or tierType
		hasInvalidTierType = Tier['types'][string.lower(tierType or '')] == nil

		output = output .. tierType .. '&nbsp;(' .. tierText .. ')'
	else
		output = output .. tierText
	end

	output = output .. ']]' ..
		(hasInvalidTier and '[[Category:Pages with invalid Tier]]' or '') ..
		(hasInvalidTierType and '[[Category:Pages with invalid Tiertype]]' or '')

	return output
end

return CustomSeries
