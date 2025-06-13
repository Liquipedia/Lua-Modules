---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Config = {}

-- These are constants, you don't need to touch them
-- unless values for liquipediatiertype change
Config.TIER_TYPE_GENERAL = 'general'
Config.TIER_TYPE_QUALIFIER = 'qualifier'
Config.TIER_TYPE_WEEKLY = 'weekly'
Config.TIER_TYPE_MONTHLY = 'monthly'
Config.TIER_TYPE_MISC = 'misc'
Config.TIER_TYPE_SHOW_MATCH = 'show match'
Config.MAX_NUMBER_OF_PARTICIPANTS = 5
Config.MAX_NUMBER_OF_COACHES = 3

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 5000

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 12
Config.NOTABILITY_THRESHOLD_NOTABLE = 15


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
				points = 20,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 20,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 20,
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
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
	{
		tier = 2,
		options = {
			dateLossIgnored = true,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 6,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 6,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 6,
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
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
	{
		tier = 3,
		options = {
			dateLossIgnored = true,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 4,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 4,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 4,
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
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
	{
		tier = 4,
		options = {
			dateLossIgnored = true,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 1,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 1,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 1
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
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
	{
		tier = 5,
		options = {
			dateLossIgnored = true,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0
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
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
}

-- This function adjusts the score for the placement, e.g.
-- a first placement should score more than a 10th placement.
function Config.placementDropOffFunction(tier, tierType)
	return function(score, placement)
		if tierType == Config.TIER_TYPE_QUALIFIER or
			tierType == Config.TIER_TYPE_SHOW_MATCH or
			tierType == Config.TIER_TYPE_MISC then

			return score
		end

		if tier == 1 then
			if placement <= 4 then
				return score
			elseif placement <= 8 then
				return (score - 5)
			elseif placement <= 16 then
				return (score - 10)
			end

		elseif tier == 2 or tier == 3 then
			if placement == 1 then
				return score
			elseif placement == 2 then
				return (score - 1)
			elseif placement <= 4 then
				return (score - 2)
			elseif placement <= 16 then
				return (score - 3)
			end

		elseif tier == 4 and placement == 1 then
			return score
		end

		return 0
	end
end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	return score
end

return Config
