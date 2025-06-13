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
Config.MAX_NUMBER_OF_PARTICIPANTS = 7
Config.MAX_NUMBER_OF_COACHES = 2

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 20
Config.NOTABILITY_THRESHOLD_NOTABLE = 25

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower
Config.EXTRA_DROP_OFF_TYPES = {
	Config.TIER_TYPE_GENERAL,
	Config.TIER_TYPE_MONTHLY,
	Config.TIER_TYPE_WEEKLY,
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
				points = 25,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 25,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 25,
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
				points = 10,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 10,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 10,
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
				points = 5,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 5,
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
				points = 2,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 2,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 2
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 2,
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
				points = 1,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 1,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 1,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 1,
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
-- See also the EXTRA_DROP_OFF_TYPES.
function Config.placementDropOffFunction(tier, tierType)

		return function(score, placement)
			if (tier == 1)
				or (tier == 2 and placement <= 10)
				or (tier == 3 and placement <= 10)
				or (tier == 4 and placement <= 3)
				or (tier == 5 and placement <= 3)
			then
				return score

			elseif (tier == 2 and placement <= 20)
				or (tier == 4 and placement <= 5)
			then
				return (score * 0.5)

			elseif (tier == 3 and placement <= 20) then
				return (score * 0.4)

			elseif ((tier == 2 or tier == 3) and (placement <= 30)) then
				return (score * 0.2)

			elseif (tier == 2) then
				return (score * 0.1)

			else
				return (score * 0)
			end

		end

end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	return score
end

return Config
