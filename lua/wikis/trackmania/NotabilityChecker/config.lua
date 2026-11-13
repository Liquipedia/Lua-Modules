---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@class TrackManiaNotabilityCheckerConfig: NotabilityCheckerConfig
local Config = {}

-- These are constants, you don't need to touch them
-- unless values for liquipediatiertype change
Config.TIER_TYPE_GENERAL = 'general'
Config.TIER_TYPE_QUALIFIER = 'qualifier'
Config.TIER_TYPE_WEEKLY = 'weekly'
Config.TIER_TYPE_MONTHLY = 'monthly'
Config.TIER_TYPE_MISC = 'misc'
Config.TIER_TYPE_SHOW_MATCH = 'showmatch'
Config.TIER_TYPE_CAMPAIGN = 'campaign'
Config.MAX_NUMBER_OF_COACHES = 2

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 250
Config.NOTABILITY_THRESHOLD_NOTABLE = 250

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
				points = 250,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CAMPAIGN,
				points = 125,
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
				points = 150,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CAMPAIGN,
				points = 75,
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
				points = 100,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CAMPAIGN,
				points = 50,
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
				points = 40,
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
				name = Config.TIER_TYPE_CAMPAIGN,
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
		tier = 5,
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
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CAMPAIGN,
				points = 10,
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

-- Currently the score ranges are used but in the future a more simple method might get added
Config.scoreRanges = {
	-- "Tier 1"
	{
		{max = 1, points = 250},
		{max = 4, points = 150},
		{max = 8, points = 150},
		{max = 16, points = 100},
		{max = math.huge, points = 10}
	},
	-- "Tier 2"
	{
		{max = 1, points = 150},
		{max = 4, points = 75},
		{max = 8, points = 75},
		{max = 16, points = 20},
		{max = math.huge, points = 5}
	},
	-- "Tier 3"
	{
		{max = 1, points = 100},
		{max = 4, points = 50},
		{max = 8, points = 20},
		{max = 16, points = 10},
		{max = math.huge, points = 5}
	},
	-- "Tier 4"
	{
		{max = 1, points = 40},
		{max = 4, points = 20},
		{max = 8, points = 10},
		{max = 16, points = 5},
		{max = math.huge, points = 2}
	},
	-- "Tier 5"
	{
		{max = 1, points = 20},
		{max = 4, points = 10},
		{max = 8, points = 5},
		{max = 16, points = 2},
		{max = math.huge, points = 0}
	}
}

--- This function adjusts the score for the placement, e.g.
--- a first placement should score more than a 10th placement.
--- See also the EXTRA_DROP_OFF_TYPES and NO_POINTS_TYPES.
---@param tier string|integer
---@param tierType string
---@return NotabilityCheckerDropOffFunction
function Config.placementDropOffFunction(tier, tierType)
	-- If for some reason the tier is not one of the defined ones return 0 for weight
	if not Config.scoreRanges[tier] then
		return function(score, placement) return 0 end
	end

	-- Campaign gives 50% of points
	local isCampaign = (tierType ~= nil) and (tierType:lower() == Config.TIER_TYPE_CAMPAIGN)

	-- Other non-general tier types (Qualifiers, Showmatches, Weekly, Miscellaneous, Monthly all give 0 points)
	if (tierType ~= nil) and (tierType:lower() ~= Config.TIER_TYPE_GENERAL) and not isCampaign then
		return function(score, placement)
			return 0
		end
	end

	return function(score, placement)
		for _, range in ipairs(Config.scoreRanges[tier]) do
			if placement <= range.max then
				local points = range.points

				if isCampaign then
					points = points * 0.5
				end

				return points
			end
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
