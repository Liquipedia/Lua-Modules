---
-- @Liquipedia
-- page=Module:NotabilityChecker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Config = require('Module:NotabilityChecker/config')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local NotabilityChecker = {}

local LANG = mw.getContentLanguage()
local NOW = os.time()
local SECONDS_IN_YEAR = 365.2425 * 86400

NotabilityChecker.LOGGING = true

function NotabilityChecker.run(args)

	local weight = 0
	local output = ''
	local isTeamResult = args.team ~= nil

	if args.player1 then
		local people = {}
		local index = 1
		while not String.isEmpty(args['player' .. tostring(index)]) do
			local person = args['player' .. tostring(index)]
			table.insert(people, person)
			index = index + 1
		end
		weight, output = NotabilityChecker._calculateRosterNotability(args.team, people)
	elseif args.team then
		weight, output = NotabilityChecker._runForTeam(args.team)
	end

	output = output .. '===Summary===\n'
		.. '<b>Final weight:</b> ' .. tostring(weight) .. '\n\n'
		.. 'This means this ' .. (isTeamResult and 'team' or 'person')

	if weight >= Config.NOTABILITY_THRESHOLD_NOTABLE then
		output = output .. ' is <b>NOTABLE</b>\n'
	elseif weight >= Config.NOTABILITY_THRESHOLD_MIN then
		output = output .. ' is <b>OPEN FOR DISCUSSION</b>\n'
	else
		output = output .. ' is <b>NOT NOTABLE</b>\n'
	end

	return output
end

function NotabilityChecker._runForTeam(team)
	team = mw.ext.TeamLiquidIntegration.resolve_redirect(team)
	local weight = NotabilityChecker._calculateTeamNotability(team)

	local output = ''
	output = output .. '===Team Results===\n'
	output = output .. mw.getCurrentFrame():expandTemplate{ title = 'NotabilityTeamMatchesTable', args = {title = team} }
	output = output .. '<b>Weight:</b> ' .. tonumber(weight) .. '\n\n'

	return weight, output
end

function NotabilityChecker._calculateRosterNotability(team, people)
	local weight = 0
	local output = ''
	if team then
		local teamWeight
		teamWeight, output = NotabilityChecker._runForTeam(team)
		weight = weight + teamWeight
	end

	output = output .. '===People Results===\n'

	local average = 0
	for _, person in pairs(people) do
		local personWeight = NotabilityChecker._calculatePersonNotability(person)
		output = output .. mw.getCurrentFrame():expandTemplate{
			title = 'NotabilityPlayerMatchesTable', args = {title = person}}
		output = output .. '*<b>Person:</b> [[' .. person .. ']] <b>Weight:</b> ' ..
			tonumber(personWeight) .. '\n\n'
			average = average + tonumber(personWeight or 0)
	end

	average = average / Table.size(people)
	weight = weight + average

	return weight, output
end

function NotabilityChecker._calculateTeamNotability(team)
	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = Config.PLACEMENT_LIMIT,
		conditions = '[[opponentname::' .. team .. ']]',
		query = 'pagename, tournament, date, placement, liquipediatier, liquipediatiertype, extradata, mode',
	})

	return NotabilityChecker._calculateWeight(data)
end

function NotabilityChecker._calculatePersonNotability(person)
	person = mw.ext.TeamLiquidIntegration.resolve_redirect(person)

	-- Add conditions.
	-- We check for names with spaces, then names with underscores.
	local conditions = {}
	for _, name in pairs({person, (person:gsub(' ', '_'))}) do
		table.insert(conditions, '[[opponentname::' .. name .. ']]')
		for i = 1, Config.MAX_NUMBER_OF_PARTICIPANTS do
			table.insert(conditions, '[[opponentplayers_p' .. tostring(i) .. '::' .. name .. ']]')
		end
		for i = 1, Config.MAX_NUMBER_OF_COACHES do
			table.insert(conditions, '[[opponentplayers_c' .. tostring(i) .. '::' .. name .. ']]')
		end
	end

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		limit = Config.PLACEMENT_LIMIT,
		conditions = table.concat(conditions, ' OR '),
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
		if not Logic.isEmpty(placement.placement) then
			if NotabilityChecker.LOGGING then
				mw.log('Tournament: ' .. placement.tournament)
			end

			local weight = NotabilityChecker.calculateTournament(
				placement.liquipediatier, placement.liquipediatiertype, placement.placement,
				placement.date, placement.extradata.notabilitymod, placement.mode
			)
			table.insert(weights, weight)
		end
	end

	local finalWeight = 0
	for _, weight in pairs(weights) do
		finalWeight = finalWeight + weight
	end

	return finalWeight
end

function NotabilityChecker.calculateTournament(tier, tierType, placement, date, notabilityMod, mode)
	local dateLossModifier = NotabilityChecker._calculateDateLoss(date)
	local notabilityModifier = NotabilityChecker._parseNotabilityMod(notabilityMod)
	local parsedTier, parsedTierType = NotabilityChecker._parseTier(tier, tierType)

	local weight = NotabilityChecker._calculateWeightForTournament(
		parsedTier, parsedTierType, placement, dateLossModifier, notabilityModifier, mode
	)

	if NotabilityChecker.LOGGING then
		mw.log('weight: ' .. weight,
			'mod: ' .. notabilityModifier,
			'mode: ' .. mode
		)
	end

	return weight
end

function NotabilityChecker._calculateWeightForTournament(tier, tierType, placement, dateLoss, notabilityMod, mode)
	if Logic.isEmpty(tier) then
		return 0
	end

	local weightForTier = Array.find(
		Config.weights, function(tierWeights) return tierWeights['tier'] == tier end
		)

	if not weightForTier then
		return 0
	end

	local tierPoints = (Array.find(
		weightForTier['tiertype'],
		function(pointsForType)
			return pointsForType['name'] == (tierType or Config.TIER_TYPE_GENERAL)
		end
	) or {}).points

	if not tierPoints then
		return 0
	end

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
	if Logic.isEmpty(placement) then
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
		local one, _ = placement:match('([^-]+)-([^-]+)')
		placement = tonumber(one)
	else
		placement = tonumber(placement)
	end

	return placement
end

function NotabilityChecker._parseTier(tier, tierType)
	if String.isEmpty(tierType) then
		return tonumber(tier), nil
	end

	return tonumber(tier), tierType:lower()
end

function NotabilityChecker._parseNotabilityMod(notabilityMod)
	if Logic.isEmpty(notabilityMod) or notabilityMod == 0 then
		return 1
	end

	return tonumber(notabilityMod)
end

function NotabilityChecker._calculateDateLoss(date)
	local timestamp = LANG:formatDate('U', date)
	local differenceSeconds = NOW - timestamp

	-- If given received a date in the future, set the modifier from date to 1
	-- This can happen due to editor mistake on a prizepool, or due to incorrectly setup prizepool/teamcard interaction
	if differenceSeconds < 0 then
		return 1
	end

	return math.floor(differenceSeconds / SECONDS_IN_YEAR) + 1
end

return Class.export(NotabilityChecker, {exports = {'run'}})
