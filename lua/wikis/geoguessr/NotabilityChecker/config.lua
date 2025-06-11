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

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

Config.MAX_NUMBER_OF_PARTICIPANTS = 7
Config.MAX_NUMBER_OF_COACHES = 2

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 13
Config.NOTABILITY_THRESHOLD_NOTABLE = 15

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower.
Config.EXTRA_DROP_OFF_TYPES = {
	Config.TIER_TYPE_GENERAL,
	Config.TIER_TYPE_MONTHLY,
	Config.TIER_TYPE_WEEKLY,
	Config.TIER_TYPE_QUALIFIER,
	Config.TIER_TYPE_MISC,
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
				points = 20,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0.5,
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
				points = 12
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0.5,
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
				points = 6,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0.5,
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
				points = 3,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0.5,
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
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0.5,
			},
		},
	},
	{
		tier = -1,
		options = {
			dateLossIgnored = true,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0.5,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0.5,
			},
		},
	},
}

-- Currently the score ranges are used but in the future a more simple method might get added
Config.scoreRanges = {
	-- "Tier 1"
	{
		{max = 16, points = 20},
		{max = math.huge, points = 15} -- "Other"
	},
	-- "Tier 2"
	{
		{max = 1, points = 12},
		{max = 4, points = 10},
		{max = 8, points = 7},
		{max = 12, points = 4},
		{max = 16, points = 2},
		{max = math.huge, points = 1} -- "Other"
	},
	-- "Tier 3"
	{
		{max = 1, points = 6},
		{max = 4, points = 3},
		{max = 8, points = 2},
		{max = 12, points = 1},
		{max = math.huge, points = 0.5} -- "Other"
	},
	-- "Tier 4"
	{
		{max = 1, points = 3},
		{max = 4, points = 1},
		{max = math.huge, points = 0.5} -- "Other"
	},
	-- "Tier 5"
	{
		{max = 1, points = 1},
		{max = math.huge, points = 0.5} -- "Other"
	}
}

-- 1st Place Qualification points
Config.scoreRangeQuali = {5, 3, 2, 0.5, 0.5}

-- This function adjusts the score for the placement, e.g.
-- a first placement should score more than a 10th placement.
-- See also the EXTRA_DROP_OFF_TYPES and NO_POINTS_TYPES.
function Config.placementDropOffFunction(tier, tierType)
	-- Return scoreRangeQuali or score if tiertype is not equal to general
	if (tierType ~= nil) and (tierType:lower() ~= Config.TIER_TYPE_GENERAL) then
		return function(score, placement)
			if (tierType:lower() == Config.TIER_TYPE_QUALIFIER) and (placement == 1) then
				return Config.scoreRangeQuali[tier]
			else
				return score
			end
		end
	end

	return function(score, placement)
        -- The current notability guidelines award set amount of points based on placement and tier of event.
		for _, range in ipairs(Config.scoreRanges[tier]) do
			if placement <= range.max then
				local points = range.points
				return points
			end
		end
	end
end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	return score
end

return Config
