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

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

Config.MAX_NUMBER_OF_PARTICIPANTS = 20
Config.MAX_NUMBER_OF_COACHES = 5

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 300
Config.NOTABILITY_THRESHOLD_NOTABLE = 300

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower.
Config.EXTRA_DROP_OFF_TYPES = {
}

-- These are all the liquipediatiertypes which currently don't award
-- points according to the osu! Notability Guidelines.
Config.NO_POINTS_TYPES = {
	Config.TIER_TYPE_QUALIFIER, Config.TIER_TYPE_WEEKLY, Config.TIER_TYPE_MONTHLY, Config.TIER_TYPE_SHOW_MATCH
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
				points = 300,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
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
				points = 150,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
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
				points = 30,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
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
				points = 2,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
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
				points = 0,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
		},
	},
}

-- Currently the score ranges are used but in the future a more simple method might get added
Config.scoreRanges = {
    -- "Tier 1"
    {
        {max = 4, points = 300},
        {max = 6, points = 250},
        {max = 8, points = 200},
        {max = 16, points = 100},
        {max = math.huge, points = 50} -- "Other"
    },
    -- "Tier 2"
    {
        {max = 1, points = 150},
        {max = 2, points = 100},
        {max = 4, points = 80},
        {max = 6, points = 60},
        {max = 8, points = 40},
        {max = 16, points = 20},
        {max = math.huge, points = 10} -- "Other"
    },
	-- "Tier 3"
    {
        {max = 1, points = 30},
        {max = 2, points = 20},
        {max = 4, points = 15},
        {max = 6, points = 10},
        {max = 8, points = 7},
        {max = 16, points = 3},
        {max = math.huge, points = 2} -- "Other"
    },
	-- "Tier 4"
    {
        {max = 1, points = 5},
        {max = 2, points = 4},
        {max = 4, points = 3},
        {max = 6, points = 2},
        {max = 8, points = 1},
        {max = math.huge, points = 0} -- "Other"
    },
	-- "Tier 5"
    {
        {max = 1, points = 2},
        {max = 2, points = 1},
        {max = math.huge, points = 0} -- "Other"
    }
}

-- This function adjusts the score for the placement, e.g.
-- a first placement should score more than a 10th placement.
-- See also the EXTRA_DROP_OFF_TYPES and NO_POINTS_TYPES.
function Config.placementDropOffFunction(tier, tierType)
	-- osu! is currently setting 0 points for the NO_POINTS_TYPES types
	-- but might change in the future

	if tierType ~= nil and Table.includes(Config.NO_POINTS_TYPES, tierType:lower()) then
		return function(score, placement) return 0 end
	end

	return function(score, placement)
        -- Workaround since in the main checker module the mode modifiers are applied before this function
		local scoreForFirst = Config.scoreRanges[tier][1]
		local needModifier = false
		if (score > scoreForFirst.points) then
			needModifier = true
		end

        -- The current notability guidelines award set amount of points based on placement and tier of event.
		for _, range in ipairs(Config.scoreRanges[tier]) do
			if placement <= range.max then
				local points = range.points

				if needModifier == true then
					points = points *1.2
				end

				return points
			end
		end
	end
end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	if string.lower(mode or '') == 'taiko' then
        return score * 1.2
    end

	if string.lower(mode or '') == 'catch' then
        return score * 1.2
    end

	if string.lower(mode or '') == 'mania 7k' then
        return score * 1.2
    end

	return score
end

return Config
