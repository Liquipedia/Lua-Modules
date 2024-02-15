---
-- @Liquipedia
-- wiki=trackmania
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
Config.TIER_TYPE_SHOW_MATCH = 'showmatch'
Config.TIER_TYPE_CAMPAIGN = 'campaign'
Config.MAX_NUMBER_OF_PARTICIPANTS = 20
Config.MAX_NUMBER_OF_COACHES = 2

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

-- Which LPDB placement parameters do we care about?
Config.PLACEMENT_QUERY =
	'pagename, tournament, date, placement, liquipediatier, ' ..
	'liquipediatiertype, players, extradata, mode'

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 20
Config.NOTABILITY_THRESHOLD_NOTABLE = 25

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
				name = Config.TIER_TYPE_CAMPAIGN,
				points = 25,
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
		tier = 3,
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
				points = 3,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 3
			},
			{
				name = Config.TIER_TYPE_CAMPAIGN,
				points = 3,
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
-- a first placement should score more than a 17th placement.
-- See also the EXTRA_DROP_OFF_TYPES.
function Config.placementDropOffFunction(tier, tierType)

		return function(score, placement)
			if (score == 0)
				or (tier == 1 and placement <= 16)
				or (tier == 2 and placement <= 8)
				or (tier == 3 and placement <= 3)
				or (tier == 4 and placement <= 3)
			then
				return score

			elseif (tier == 1 and placement > 16)
				or (tier == 2 and placement <= 16)
				or (tier == 3 and placement <= 8)
			then
				return (2)
			else
				return (1)
			end

		end

end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	return score
end

return Config
