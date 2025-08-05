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
Config.TIER_TYPE_SHOWMATCH = 'showmatch'
Config.TIER_TYPE_INDIVIDUAL = 'individual'
Config.MAX_NUMBER_OF_PARTICIPANTS = 10
Config.MAX_NUMBER_OF_COACHES = 2

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 10
Config.NOTABILITY_THRESHOLD_NOTABLE = 8


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
				points = 10,
			},
			{
				name = Config.TIER_TYPE_INDIVIDUAL,
				points = 10,
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
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
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
				points = 8,
			},
			{
				name = Config.TIER_TYPE_INDIVIDUAL,
				points = 8,
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
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
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
				name = Config.TIER_TYPE_INDIVIDUAL,
				points = 5,
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
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
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
				name = Config.TIER_TYPE_INDIVIDUAL,
				points = 2,
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
				name = Config.TIER_TYPE_SHOWMATCH,
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
				points = 0,
			},
			{
				name = Config.TIER_TYPE_INDIVIDUAL,
				points = 1,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
}

--- This function adjusts the score for the placement, e.g.
--- a first placement should score more than a 10th placement.
---@param tier string|integer
---@param tierType string
---@return fun(number, number): number
function Config.placementDropOffFunction(tier, tierType)

		return function(score, placement)
			if (tier == 1 or placement == 1) then
				return score

			elseif (tier == 2 and placement <= 3) then
				return score

			elseif (tier == 2 and placement <= 8) then
				return (score * 5/8)

			elseif (tier == 2 and placement <= 12) then
				return (score * 3/8)

			elseif (tier == 3 and placement <= 2) then
				return score

			elseif (tier == 3 and placement == 3) then
				return (score * 3/5)

			elseif (tier == 3 and placement <= 8) then
				return (score * 2/5)

			elseif (tier == 4 and placement == 2) then
				return (score * 1/2)
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
