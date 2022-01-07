---
-- @Liquipedia
-- wiki=commons
-- page=Module:NotabilityChecker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Config = require('Module:NotabilityChecker/config')
local String = require('Module:String')
local LuaUtils = require('Module:LuaUtils')
local Array = require('Module:Array')
local Table = require('Module:Table')

local NotabilityChecker = {}

local _lang = mw.language.new('en')
local _NOW = os.time()
local _SECONDS_IN_YEAR = 365.2425 * 86400

function NotabilityChecker.run(args)

	local weight = 0
	local output = ''
	local isTeamResult = args.team ~= nil

	if args.player1 then
		local players = {}
		local index = 1
		while not String.isEmpty(args['player' .. tostring(index)]) do
			local player = args['player' .. tostring(index)]
			table.insert(players, player)
			index = index + 1
		end
		weight, output = NotabilityChecker._calculateRosterNotability(args.team, players)
	elseif args.team then
		weight, output = NotabilityChecker._runForTeam(args.team)
	end

	output = output .. '===Summary===\n'
	output = output .. '\'\'\'Final weight:\'\'\' ' .. tostring(weight) .. '\n\n'

	if weight < Config.NOTABILITY_THRESHOLD_NOTABLE and weight > Config.NOTABILITY_THRESHOLD_MIN then
		output = output .. 'This means this ' .. (isTeamResult and 'team' or 'player') ..
		' is \'\'\'OPEN FOR DISCUSSION\'\'\'\n'
	elseif weight < Config.NOTABILITY_THRESHOLD_MIN then
		output = output .. 'This means this ' .. (isTeamResult and 'team' or 'player') ..
		' is \'\'\'NOT NOTABLE\'\'\'\n'
	else
		output = output .. 'This means this ' .. (isTeamResult and 'team' or 'player') ..
		' is \'\'\'NOTABLE\'\'\'\n'
	end

	return output
end

function NotabilityChecker._runForTeam(team)
	team = mw.ext.TeamLiquidIntegration.resolve_redirect(team)
	local weight = NotabilityChecker._calculateTeamNotability(team)

	local output = ''
	output = output .. '===Team Results===\n'
	output = output .. mw.getCurrentFrame():expandTemplate{ title = 'NotabilityTeamMatchesTable', args = {title = team} }
	output = output .. '\'\'\'Weight:\'\'\' ' .. tonumber(weight) .. '\n\n'

	return weight, output
end

function NotabilityChecker._calculateRosterNotability(team, players)
	local weight = 0
	local output = ''
	if team then
		local teamWeight
		teamWeight, output = NotabilityChecker._runForTeam(team)
		weight = weight + teamWeight
	end

	output = output .. '===Player Results===\n'

	local playerAverage = 0
	for _, player in pairs(players) do
		local playerWeight = NotabilityChecker._calculatePlayerNotability(player)
		output = output .. mw.getCurrentFrame():expandTemplate{
			title = 'NotabilityPlayerMatchesTable', args = {title = player}}
		output = output .. '*\'\'\'Player:\'\'\' [[' .. player .. ']] \'\'\'Weight:\'\'\' ' ..
			tonumber(playerWeight) .. '\n\n'
		playerAverage = playerAverage + tonumber(playerWeight or 0)
	end

	playerAverage = playerAverage / Table.size(players)
	weight = weight + playerAverage

	return weight, output
end

function NotabilityChecker._calculateTeamNotability(team)
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = Config.PLACEMENT_LIMIT,
		conditions = '[[participant::' .. team .. ']]',
		query = Config.PLACEMENT_QUERY,
	})

	return NotabilityChecker._calculateWeight(data)
end

function NotabilityChecker._calculatePlayerNotability(player)
	player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)

	local conditions = '[[players_p' .. tostring(1) .. '::' .. player .. ']]' ..
		' OR [[participant::' .. player .. ']]'
	for i = 2, Config.MAX_NUMBER_OF_PARTICIPANTS do
		conditions = conditions .. ' OR [[players_p' .. tostring(i) .. '::' .. player .. ']]'
	end
	for i= 1, Config.MAX_NUMBER_OF_COACHES do
		conditions = conditions .. ' OR [[players_c' .. tostring(i) .. '::' .. player .. ']]'
	end

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = Config.PLACEMENT_LIMIT,
		conditions = conditions,
		query = Config.PLACEMENT_QUERY,
	})
	return NotabilityChecker._calculateWeight(data)
end

function NotabilityChecker._calculateWeight(placementData)
	if type(placementData) ~= 'table' or placementData[1] == nil then
		return 0
	end

	local weights = {}

	for _, placement in pairs(placementData) do
		if not String.isEmpty(placement.placement) then
			local dateLoss = NotabilityChecker._calculateDateLoss(placement.date)
			local notabilityMod = NotabilityChecker._parseNotabilityMod(
				placement.extradata['notabilitymod'])
			local tier, tierType = NotabilityChecker._parseTier(placement)

			local weight = NotabilityChecker._calculateWeightForTournament(
				tier, tierType, placement.placement, dateLoss, notabilityMod, placement.mode)
			table.insert(weights, weight)
			mw.log('Tournament: ' .. placement.tournament ..
			'    weight: ' .. weight .. '    mod: ' .. notabilityMod ..
			'    mode: ' .. placement.mode
			)
		end
	end

	local finalWeight = 0
	for _, weight in pairs(weights) do
		finalWeight = finalWeight + weight
	end

	return finalWeight
end

function NotabilityChecker._calculateWeightForTournament(tier, tierType, placement, dateLoss, notabilityMod, mode)
	if String.isEmpty(tier) then
		return 0
	end

	local weightForTier = Array.find(
		Config.weights, function(tierWeights) return tierWeights['tier'] == tier end
		)

	local tierPoints = Array.find(
		weightForTier['tiertype'],
		function(pointsForType)
			return pointsForType['name'] == (tierType or Config.TIER_TYPE_GENERAL)
		end
	)['points']
	local placementDropOffFunction = Config.placementDropOffFunction(tier, tierType)

	local placementValue = NotabilityChecker._preparePlacement(placement)

	if placementValue == nil then
		return 0
	end

	local options = weightForTier['options']
	if options ~= nil and options['dateLossIgnored'] == true then
		dateLoss = 1
	end

	local weight = notabilityMod * (tierPoints / dateLoss)
	weight = Config.adjustScoreForMode(weight, mode)

	return placementDropOffFunction(weight, placementValue)
end

function NotabilityChecker._preparePlacement(placement)
	if String.isEmpty(placement) then
		return nil
	end

	placement = placement:lower()

	-- Deal with forfeits
	if placement == 'l' then
		placement = '2'
	elseif placement == 'w' then
		placement = '1'
	end

	if string.find(placement, '-', 1, true) then
		local one, _ = placement:match("([^-]+)-([^-]+)")
		placement = tonumber(one)
	else
		placement = tonumber(placement)
	end

	return placement
end

function NotabilityChecker._parseTier(placement)
	if String.isEmpty(placement.liquipediatiertype) then
		return tonumber(placement.liquipediatier), nil
	end

	-- If true, this is a wiki that uses a legacy system where extradata.liquipediatier
	-- contains the numerical liquipediatier, and liquipediatier contains the type.
	local isWikiThatUsesLiquipediaTier2 = placement.liquipediatier == placement.liquipediatiertype

	if not isWikiThatUsesLiquipediaTier2 then
		return tonumber(placement.liquipediatier), placement.liquipediatiertype:lower()
	end

	local liquipediaTier2 = placement.extradata['liquipediatier2']
	if String.isEmpty(liquipediaTier2) then
		local tournament = LuaUtils.lpdb.getSingle('tournament',
			{ conditions = '[[pagename::' .. placement.pagename .. ']]' })
		liquipediaTier2 = (tournament or { extradata = {} }).extradata['liquipediatier2'] or ''
	end

	return tonumber(liquipediaTier2), placement.liquipediatiertype:lower()
end

function NotabilityChecker._parseNotabilityMod(notabilityMod)
	if String.isEmpty(notabilityMod) or notabilityMod == 0 then
		return 1
	end

	return tonumber(notabilityMod)
end

function NotabilityChecker._calculateDateLoss(date)
	local timestamp = _lang:formatDate('U', date)
	local differenceSeconds = _NOW - timestamp
	return math.floor(differenceSeconds / _SECONDS_IN_YEAR) + 1
end

function NotabilityChecker._firstToLower(s)
	return s:sub(1, 1):lower() .. s:sub(2)
end

return Class.export(NotabilityChecker)
