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

local Sc2Series = {}

function Sc2Series.run(frame)
	local series = Series(frame)
	series.addCustomCells = Sc2Series.addCustomCells
	series.createTier = Sc2Series.createTier
	return series:createInfobox(frame)
end

function Sc2Series.addCustomCells(series, infobox, args)
	infobox:cell('Server', args.server)
	infobox:cell('Type', args.type)
	infobox:cell('Format', args.format)
	if args.prizepooltot ~= 'false' then
		infobox:cell('Total prize money', Sc2Series._getSeriesPrizepools(args))
	end
	infobox:cell('Game version', Sc2Series._getGameVersion(string.lower(args.game or ''), args.patch or '', args))

	Sc2Series._addCustomVariables(args)

	return infobox
end

function Sc2Series._getSeriesPrizepools(args)
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

function Sc2Series._getGameVersion(game, patch, args)
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

function Sc2Series._addCustomVariables(args)
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
		Sc2Series._setDateMatchVar(args.date, args.edate, args.sdate)
	end
end

function Sc2Series._setDateMatchVar(date, edate, sdate)
	date = string.match(date or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(edate or '', '%d%d%d%d%-%d%d%-%d%d')
		or string.match(sdate or '', '%d%d%d%d%-%d%d%-%d%d') or ''

	VarDefine('date', date)
end

--function for custom tier handling
function Sc2Series.createTier(self, tier, tierType)
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

return Sc2Series
