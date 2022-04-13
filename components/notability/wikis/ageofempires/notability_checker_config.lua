---
-- @Liquipedia
-- wiki=ageofempires
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
Config.TIER_TYPE_MISC = 'misc'

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

-- How many players can be in a team?
Config.MAX_NUMBER_OF_PARTICIPANTS = 10

-- How many coaches can be in a team?
Config.MAX_NUMBER_OF_COACHES = 1

-- Which LPDB placement parameters do we care about?
Config.PLACEMENT_QUERY =
	'pagename, tournament, date, placement, liquipediatier, ' ..
	'liquipediatiertype, players, extradata, mode'

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 400
Config.NOTABILITY_THRESHOLD_NOTABLE = 600

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower
Config.EXTRA_DROP_OFF_TYPES = {
	Config.TIER_TYPE_QUALIFIER,
	Config.TIER_TYPE_SHOW_MATCH,
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
				points = 5000,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 1000,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 500,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 500,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 2000,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 2000,
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
				name = Config.TIER_TYPE_QUALIFIER,
				points = 400,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 200,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 200,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 1500,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 1500,
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
				points = 1000,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 200,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 800,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 800,
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
				points = 500,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_MISC,
				points = 50,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 400,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 400,
			},
		},
	},
	{
		tier = 9,
		options = {
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_SHOW_MATCH,
				points = 100,
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
	if mode == "2v2" or "3v3" or "4v4" then
		modeMod = 0.5
	end
	return score * modeMod
end

return Config