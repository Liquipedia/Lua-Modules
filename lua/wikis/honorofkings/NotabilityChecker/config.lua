---
-- @Liquipedia
-- page=Module:NotabilityChecker/config
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = Lua.import('Module:Table')
local Config = {}

-- These are constants, you don't need to touch them
-- unless values for liquipediatiertype change
Config.TIER_TYPE_GENERAL = 'general'
Config.TIER_TYPE_QUALIFIER = 'qualifier'
Config.TIER_TYPE_MISC = 'misc'
Config.TIER_TYPE_SHOWMATCH = 'showmatch'

-- How many placements should we retrieve from LPDB for a team/player?
Config.PLACEMENT_LIMIT = 5000

Config.MAX_NUMBER_OF_PARTICIPANTS = 12
Config.MAX_NUMBER_OF_COACHES = 5

-- These are the notability thresholds needed by a team/player
Config.NOTABILITY_THRESHOLD_MIN = 30
Config.NOTABILITY_THRESHOLD_NOTABLE = 30

-- These are all the liquipediatiertypes which should be extra "penalised"
-- for a lower placement, see also the placementDropOffFunction below.
-- Generally these types will award the same points for first, but then
-- quickly decrease the point rewards as the placement gets lower
Config.EXTRA_DROP_OFF_TYPES = {}

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
				points = 30,
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
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 20,
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
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 10,
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
			dateLossIgnored = false,
		},
		tiertype = {
			{
				name = Config.TIER_TYPE_GENERAL,
				points = 3,
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
			dateLossIgnored = false,
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
				name = Config.TIER_TYPE_MISC,
				points = 0,
			},
		},
	},
}

--- This function adjusts the score for the placement, e.g.
--- a first placement should score more than a 10th placement.
--- See also the EXTRA_DROP_OFF_TYPES.
---@param tier string|integer
---@param tierType string
---@return fun(number, number): number
function Config.placementDropOffFunction(tier, tierType)
	return function(score, placement)
		if (score == 0)
			or (tier == 1 and placement <= 8)
			or (tier == 2 and placement <= 4)
			or (tier == 3 and placement <= 2)
			or (tier == 4 and placement <= 2)
		then
			return score

		elseif (tier == 1 and placement <= 16) then
			return 20

		elseif (tier == 1 and placement > 16) then
			return 15

		elseif (tier == 2 and placement <= 8) then
			return 10

		elseif (tier == 3 and placement <= 4) then
			return 5

		elseif (tier == 2 and placement <= 16) then
			return 4

		elseif (tier == 3 and placement <= 8) then
			return 3

		elseif (tier == 2 and placement > 16)
			or (tier == 3 and placement <= 16)
			or (tier == 4 and placement <= 4)
		then
			return 1

		else
			return 0
        end
	end
end

-- Adjusts the score to compensate for the mode, you might
-- want to decrease the points given for a certain mode
function Config.adjustScoreForMode(score, mode)
	return score
end

return Config
