---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Series = require('Module:Infobox/Series')
local Autopatch = require('Module:Automated Patch')._main
local SeriesTotalPrize = require('Module:SeriesTotalPrize')._get
local Tier = require('Module:Tier')
local Json = require('Module:Json')
local VarDefine = require('Module:Variables').varDefine
local Namespace = require('Module:Namespace')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')
local Class = require('Module:Class')

local _GAME_WOL = 'wol'
local _GAME_HOTS = 'hots'
local _GAME_LOTV = 'lotv'
local _GAME_MOD = 'mod'

local _GAMES = {
	[_GAME_WOL] = {'Wings of Liberty', 'WoL'},
	[_GAME_HOTS] = {'Heart of the Swarm', 'HotS'},
	[_GAME_LOTV] = {'Legacy of the Void', 'LotV'},
	[_GAME_MOD] = {'mod', 'mod'}
}

local CustomInjector = Class.new(Injector)

local CustomSeries = {}

local _series

function CustomSeries.run(frame)
	local series = Series(frame)
	series.createTier = CustomSeries.createTier
	series.createWidgetInjector = CustomSeries.createWidgetInjector
	_series = series
	return series:createInfobox(frame)
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Game version',
		content = {
			CustomSeries._getGameVersion(
				string.lower(_series.args.game or ''), _series.args.patch or '', _series.args)
		}
	})
	table.insert(widgets, Cell({
		name = 'Server',
		content = {_series.args.server}
	}))
	table.insert(widgets, Cell({
		name = 'Type',
		content = {_series.args.type}
	}))
	table.insert(widgets, Cell({
		name = 'Format',
		content = {_series.args.format}
	}))
	table.insert(widgets, Builder({
		builder = function()
			if _series.args.prizepooltot ~= 'false' then
				return {
					Cell{
						name = 'Total prize money',
						CustomSeries._getSeriesPrizepools(_series.args)
					}
				}
			end
		end
	}))
	CustomSeries._addCustomVariables(_series.args)
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'liquipediatier' then
		return {
			Cell{
				name = 'Liquipedia Tier',
				contents = {
					CustomSeries.createTier(
						_series.args.liquipediatier, (_series.args.liquipediatiertype or _series.args.tiertype))
				}

			}
		}
	end

	return widgets
end

function CustomSeries._getSeriesPrizepools(args)
	local seriesTotalPrizeInput = Json.parseIfString(args.prizepooltot or '{}')
	local series = seriesTotalPrizeInput.series or args.series or mw.title.getCurrentTitle().text

	--build args for the SeriesTotalPrize Module
	local newArgs = {
		series = series,
		limit = seriesTotalPrizeInput.limit or args.limit,
		offset = seriesTotalPrizeInput.offset or args.offset,
		external = seriesTotalPrizeInput.external or args.external,
		onlytotal = seriesTotalPrizeInput.onlytotal or args.onlytotal,
	}
	return SeriesTotalPrize(newArgs)
end

function CustomSeries._getGameVersion(game, patch, args)
	local shouldUseAutoPatch = args.autopatch or ''
	local modName = args.modname or ''
	local beta = args.beta or ''
	local epatch = args.epatch or ''
	local sdate = args.sdate or ''
	local edate = args.edate or ''
	local today = os.date('%Y-%m-%d', os.time())

	if game ~= '' or patch ~= '' then
		local gameversion
		if game == _GAME_MOD then
			gameversion = modName or 'Mod'
		elseif _GAMES[game] ~= nil then
			gameversion = '[[' .. _GAMES[game][1] .. ']][[Category:' ..
				(beta ~= '' and 'Beta ' or '') .. _GAMES[game][2] .. ' Competitions]]'
		else
			gameversion = '[[Category:' .. (beta ~= '' and 'Beta ' or '') .. ' Competitions]]'
		end

		if (shouldUseAutoPatch == 'false' or game ~= 'lotv') and epatch == '' then
			epatch = patch
		end
		if patch == '' and game == _GAME_LOTV and shouldUseAutoPatch ~= 'false' then
			patch = 'Patch ' .. (
				Autopatch({sdate ~= '' and string.lower(sdate) ~= 'tbd' and string.lower(sdate) ~= 'tba' and sdate or today}) or '')
		end
		if epatch == '' and game == 'lotv' and shouldUseAutoPatch ~= 'false' then
			epatch = 'Patch ' .. (
				Autopatch({ edate ~= '' and
							string.lower(edate) ~= 'tbd' and
							string.lower(edate) ~= 'tba' and
							edate or today
						}) or '')
		end

		local patch_display = beta ~= '' and 'Beta ' or ''

		if patch ~= '' then
			if patch == epatch then
				patch_display = patch_display .. '<br/>[[' .. patch .. ']]'
			else
				patch_display = patch_display .. '<br/>[[' .. patch .. ']] &ndash; [[' .. epatch .. ']]'
			end
		end

		--set patch variables
		VarDefine('patch', patch)
		VarDefine('epatch', epatch)

		return gameversion .. patch_display
	end
end

function CustomSeries._addCustomVariables(args)
	if
		(not Namespace.isMain()) or
		args.disable_smw == 'true' or
		args.disable_lpdb == 'true' or
		args.disable_storage == 'true'
	then
		VarDefine('disable_SMW_storage', 'true')
	else
		--needed for e.g. External Cups Lists
		local name = args.name or mw.title.getCurrentTitle().text
		VarDefine('tournament_icon', args.icon or '')
		VarDefine('featured', args.featured or '')
		VarDefine('headtohead', args.headtohead or '')
		VarDefine('tournament_tier', args.liquipediatier or '')
		VarDefine('tournament_tiertype', args.liquipediatiertype or args.tiertype or '')
		VarDefine('tournament_mode', args.mode or '1v1')
		VarDefine('tournament_ticker_name', args.tickername or name)
		VarDefine('tournament_shortname', args.shortname or '')
		VarDefine('tournament_name', name)
		VarDefine('tournament_abbreviation', args.abbreviation or args.shortname or '')
		local game = args.game
		if game then
			game = _GAMES[game] ~= nil and _GAMES[game][1] or game
		end
		VarDefine('tournament_game', game or '')
		VarDefine('tournament_type', args.type or '')
		CustomSeries._setDateMatchVar(args.date, args.edate, args.sdate)
	end
end

function CustomSeries._setDateMatchVar(date, edate, sdate)
	date = string.match(date or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(edate or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(sdate or '', '%d%d%d%d%-%d%d%-%d%d') or ''

	VarDefine('date', date)
end

--function for custom tier handling
function CustomSeries.createTier(tier, tierType)
	if tier == nil or tier == '' then
		return ''
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
