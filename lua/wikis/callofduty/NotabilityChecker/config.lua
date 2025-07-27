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
Config.MAX_NUMBER_OF_PARTICIPANTS = 8
Config.MAX_NUMBER_OF_COACHES = 2

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

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
				points = 15,
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
				points = 5,
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
				points = 12,
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
				points = 3,
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
				name = Config.TIER_TYPE_MONTHLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 1,
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
				points = 3,
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

-- This function adjusts the score for the placement, e.g.
-- a first placement should score more than a 10th placement.
function Config.placementDropOffFunction(tier, tierType)

		return function(score, placement)
			if (tierType == Config.TIER_TYPE_QUALIFIER) then
				if ((tier == 1 or tier == 2 or tier == 3) and placement == 1) then
					return score
				end

			else
				if (tier == 1 and placement <= 16) or placement == 1 then
					return score

				elseif (tier == 1) then
					return (score / 3 * 2)

				elseif (tier == 2 and placement <= 3) then
					return (score * 10/12)

				elseif (tier == 2 and placement <= 8) then
					return (score * 8/12)

				elseif (tier == 2 and placement <= 12) then
					return (score * 5/12)

				elseif (tier == 2 and placement <= 16) then
					return (score * 3/12)

				elseif (tier == 2) then
					return (score * 1/12)

				elseif (tier == 3 and placement <= 3) then
					return (score * 0.6)

				elseif (tier == 3 and placement <= 8) then
					return (score * 0.4)

				elseif (tier == 3 and placement <= 12) then
					return (score * 0.2)

				elseif (tier == 4 and placement <= 3) then
					return (score * 1/3)
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
