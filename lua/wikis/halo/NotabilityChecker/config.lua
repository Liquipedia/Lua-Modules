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
Config.TIER_TYPE_DAILY = 'daily'
Config.TIER_TYPE_FFA = 'ffa'
Config.TIER_TYPE_MISC = 'misc'
Config.TIER_TYPE_SHOW_MATCH = 'show match'
Config.TIER_TYPE_CHARITY = 'charity'

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

Config.MAX_NUMBER_OF_PARTICIPANTS = 10
Config.MAX_NUMBER_OF_COACHES = 5

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 600
Config.NOTABILITY_THRESHOLD_NOTABLE = 800

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
				points = 20000,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_DAILY,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CHARITY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0,
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
				points = 2000,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_DAILY,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CHARITY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0,
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
				points = 600,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_DAILY,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CHARITY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0,
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
				points = 350,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_DAILY,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CHARITY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0,
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
	return score
end

return Config
