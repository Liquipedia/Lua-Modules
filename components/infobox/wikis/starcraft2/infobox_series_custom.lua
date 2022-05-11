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
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')

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

local _series
local _args

function CustomSeries.run(frame)
	local series = Series(frame)
	series.createWidgetInjector = CustomSeries.createWidgetInjector
	_series = series
	_args = series.args
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
				string.lower(_series.args.game or ''), _series.args.patch or '')
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
						content = {CustomSeries._getSeriesPrizepools(_series.args)}
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
			if patch == endPatch then
				patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']]'
			else
				patchDisplay = patchDisplay .. '<br/>[[' .. patch .. ']] &ndash; [[' .. endPatch .. ']]'
			end
		end

		--set patch variables
		Variables.varDefine('patch', patch)
		Variables.varDefine('epatch', endPatch)

		return gameVersion .. patchDisplay
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

--- Allows for overriding this functionality
function Series:addToLpdb(lpdbData)
	Variables.varDefine('tournament_icon', lpdbData.icon)
	Variables.varDefine('tournament_icon_dark', lpdbData.icondark)
	return lpdbData
end

function CustomSeries._setDateMatchVar(date, edate, sdate)
	date = string.match(date or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(edate or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(sdate or '', '%d%d%d%d%-%d%d%-%d%d') or ''
	sdate = string.match(date or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(sdate or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(edate or '', '%d%d%d%d%-%d%d%-%d%d') or ''

	VarDefine('date', date)
	VarDefine('tournament_enddate', date)
	VarDefine('tournament_startdate', sdate)
end

--function for custom tier handling
function CustomSeries._createLiquipediaTierDisplay(tier, tierType)
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

	local tierDisplay = '[[' .. tier .. ' Tournaments|'

	if String.isNotEmpty(tierType) then
		tierType = buildTierText(tierType:lower(), _TIER_MODE_TYPES)
		tierDisplay = tierDisplay .. tierType .. '&nbsp;(' .. tier .. ')]]'
	else
		tierDisplay = tierDisplay .. tier .. ']]'
	end

	return tierDisplay
end

return CustomSeries
