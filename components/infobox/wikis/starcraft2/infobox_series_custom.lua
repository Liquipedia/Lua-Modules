---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Series/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Series = require('Module:Infobox/Series')
local Autopatch = require('Module:Automated Patch')
local SeriesTotalPrize = require('Module:SeriesTotalPrize')
local Tier = require('Module:Tier')
local Json = require('Module:Json')
local Variables = require('Module:Variables')
local Namespace = require('Module:Namespace')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Builder = require('Module:Infobox/Widget/Builder')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local _TODAY = os.date('%Y-%m-%d', os.time())
local _TIER_MODE_TYPES = 'types'
local _TIER_MODE_TIERS = 'tiers'
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

local _args
local _series

function CustomSeries.run(frame)
	local series = Series(frame)
	_args = series.args
	_series = series

	_args.liquipediatiertype = _args.liquipediatiertype or _args.tiertype

	series.createWidgetInjector = CustomSeries.createWidgetInjector

	return series:createInfobox(frame)
end

function CustomSeries:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Game version',
		content = {
			CustomSeries._getGameVersion(string.lower(_args.game or ''), _args.patch or '')
		}
	})
	table.insert(widgets, Cell({
		name = 'Server',
		content = {_args.server}
	}))
	table.insert(widgets, Cell({
		name = 'Type',
		content = {_args.type}
	}))
	table.insert(widgets, Cell({
		name = 'Format',
		content = {_args.format}
	}))
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

function CustomSeries._getGameVersion(game, patch)
	local shouldUseAutoPatch = (_args.autopatch or '') ~= 'false'
	local modName = _args.modname
	local betaPrefix = String.isNotEmpty(_args.beta) and 'Beta ' or ''
	local endPatch = _args.epatch
	local startDate = _args.sdate
	local endDate = _args.edate

	if String.isNotEmpty(game) or String.isNotEmpty(patch) then
		local gameVersion
		if game == _GAME_MOD then
			gameVersion = modName or 'Mod'
		elseif _GAMES[game] then
			gameVersion = '[[' .. _GAMES[game][1] .. ']]' ..
				'[[Category:' .. betaPrefix .. _GAMES[game][2] .. ' Competitions]]'
		else
			gameVersion = '[[Category:' .. betaPrefix .. 'Competitions]]'
		end

		if game == _GAME_LOTV and shouldUseAutoPatch then
			if String.isEmpty(patch) then
				patch = 'Patch ' .. (Autopatch._main({CustomSeries._retrievePatchDate(startDate)}) or '')
			end
			if String.isEmpty(endPatch) then
				endPatch = 'Patch ' .. (Autopatch._main({CustomSeries._retrievePatchDate(endDate)}) or '')
			end
		elseif String.isEmpty(endPatch) then
			endPatch = patch
		end

		local patchDisplay = betaPrefix

		if String.isNotEmpty(patch) then
			patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']]'
			if patch ~= endPatch then
				patchDisplay = patchDisplay .. ' &ndash; [[' .. endPatch .. ']]'
			end
		end

		--set patch variables
		Variables.varDefine('patch', patch)
		Variables.varDefine('epatch', endPatch)

		return gameVersion .. patchDisplay
	end
end

function CustomSeries._retrievePatchDate(dateEntry)
	return String.isNotEmpty(dateEntry)
		and dateEntry:lower() ~= 'tbd'
		and dateEntry:lower() ~= 'tba'
		and dateEntry or _TODAY
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
		Variables.varDefine('tournament_liquipediatiertype', _args.liquipediatiertype or '')
		Variables.varDefine('tournament_mode', _args.mode or '1v1')
		Variables.varDefine('tournament_ticker_name', _args.tickername or name)
		Variables.varDefine('tournament_shortname', _args.shortname or '')
		Variables.varDefine('tournament_name', name)
		Variables.varDefine('tournament_abbreviation', _args.abbreviation or _args.shortname or '')
		local game = _args.game
		if game then
			game = _GAMES[game] ~= nil and _GAMES[game][1] or game
		end
		Variables.varDefine('tournament_game', game or '')
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
function CustomSeries.createLiquipediaTierDisplay()
	local tier = _args.liquipediatier
	local tierType = _args.liquipediatiertype
	if String.isEmpty(tier) then
		return nil
	end

	local function buildTierText(tierString, tierMode)
		local tierText = Tier.text[tierMode][tierString]
		if not tierText then
			tierMode = tierMode == _TIER_MODE_TYPES and 'Tiertype' or 'Tier'
			table.insert(
				_series.warnings,
				tierString .. ' is not a known Liquipedia ' .. tierMode
					.. '[[Category:Pages with invalid ' .. tierMode .. ']]'
			)
			return ''
		else
			return tierText
		end
	end

	tier = buildTierText(tier, _TIER_MODE_TIERS)

	local tierLink = tier .. ' Tournaments'
	local tierDisplay
	if String.isNotEmpty(tierType) then
		tierType = buildTierText(tierType:lower(), _TIER_MODE_TYPES)
		tierDisplay = tierType .. '&nbsp;(' .. tier .. ')'
	else
		tierDisplay = tier
	end

	return '[[' .. tierLink .. '|' .. tierDisplay .. ']]'
end

return CustomSeries
