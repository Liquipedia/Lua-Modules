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
Config.TIER_TYPE_SHOWMATCH = 'showmatch'
Config.TIER_TYPE_FFA = 'ffa'
Config.TIER_TYPE_CHARITY = 'charity'

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 2000

-- How many players can be in a team?
Config.MAX_NUMBER_OF_PARTICIPANTS = 10

-- How many coaches can be in a team?
Config.MAX_NUMBER_OF_COACHES = 1

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 1600 -- Essentially disabled since NOTABILITY_THRESHOLD_NOTABLE is checked first
Config.NOTABILITY_THRESHOLD_NOTABLE = 1600

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower
Config.EXTRA_DROP_OFF_TYPES = {
	Config.TIER_TYPE_QUALIFIER,
	Config.TIER_TYPE_SHOWMATCH,
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
				name = Config.TIER_TYPE_SHOWMATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 2000,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 2000,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 1500,
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
				points = 2000,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 400,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 1500,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 1500,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 1000,
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
				points = 1000,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 200,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 800,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 800,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 500,
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
				points = 500,
			},
			{
				name = Config.TIER_TYPE_QUALIFIER,
				points = 100,
			},
			{
				name = Config.TIER_TYPE_SHOWMATCH,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_MONTHLY,
				points = 400,
			},
			{
				name = Config.TIER_TYPE_WEEKLY,
				points = 400,
			},
			{
				name = Config.TIER_TYPE_FFA,
				points = 200,
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
				name = Config.TIER_TYPE_SHOWMATCH,
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
			{
				name = Config.TIER_TYPE_FFA,
				points = 0,
			},
			{
				name = Config.TIER_TYPE_CHARITY,
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
	local modeMod = 1
	if mode == 'team' then
		modeMod = 0.5
	end
	return score * modeMod
end

return Config
