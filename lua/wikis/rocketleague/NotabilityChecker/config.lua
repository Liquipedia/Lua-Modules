---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Table = require('Module:Table')

local Config = {}

-- These are constants, you don't need to touch them
-- unless values for liquipediatiertype change
Config.TIER_TYPE_GENERAL = 'general'
Config.TIER_TYPE_QUALIFIER = 'qualifier'
Config.TIER_TYPE_WEEKLY = 'weekly'
Config.TIER_TYPE_MONTHLY = 'monthly'
Config.TIER_TYPE_SHOW_MATCH = 'show match'
Config.TIER_TYPE_SCHOOL = 'school'

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

Config.MAX_NUMBER_OF_PARTICIPANTS = 10
Config.MAX_NUMBER_OF_COACHES = 0

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 400
Config.NOTABILITY_THRESHOLD_NOTABLE = 500

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower
Config.EXTRA_DROP_OFF_TYPES = {
	Config.TIER_TYPE_QUALIFIER,
}

-- Weights used for tournaments
Config.weights = {
	{
		tier = 1,
		options = {
			dateLossIgnored = true,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 1000,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 250,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 250,
			},
			{
				name = Config.TIER_TYPE_SCHOOL,
				points = 500,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 200,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 50,
			},
		},
	},
	{
		tier = 2,
		options = {
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 500,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 125,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 125,
			},
			{
				name = Config.TIER_TYPE_SCHOOL,
				points = 250,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 150,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 40,
			},
		},
	},
	{
		tier = 3,
		options = {
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 350,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 75,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 75,
			},
			{
				name = Config.TIER_TYPE_SCHOOL,
				points = 150,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 30,
			},
		},
	},
	{
		tier = 4,
		options = {
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 175,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 30,
			},
			{
				name = Config.TIER_TYPE_SCHOOL,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 20,
			},
		},
	},
	{
		tier = 5,
		options = {
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 3,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 3,
			},
			{
				name = Config.TIER_TYPE_SCHOOL,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 10,
			},
		},
	},
}

-- This function adjusts the score for the placement, e.g.
-- a first placement should score more than a 10th placement.
-- See also the EXTRA_DROP_OFF_TYPES.
function Config.placementDropOffFunction(tier, tierType)
	if tierType ~= nil and Table.includes(Config.EXTRA_DROP_OFF_TYPES, tierType:lower()) then
		return function(score, placement) return score / (placement * placement) end
	end

	return function(score, placement) return score / placement end
end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	local modeMod = 1
	if mode == '2v2' then
		modeMod = 0.5
	elseif mode == '1v1' then
		modeMod = 0.25
	end
	return score * modeMod
end

return Config
