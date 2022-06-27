---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local BasicHiddenDataBox = require('Module:HiddenDataBox')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Tier = require('Module:Tier')
local Variables = require('Module:Variables')

local CustomHiddenDataBox = {}

local INVALID_TIER_WARNING = '${tierString} is not a known Liquipedia '
	.. '${tierMode}[[Category:Pages with invalid ${tierMode}]]'
local TIER_MODE_TYPES = 'types'
local TIER_MODE_TIERS = 'tiers'

function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	BasicHiddenDataBox.validateTier = CustomHiddenDataBox.validateTier
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox:addCustomVariables(args, queryResult)
	--legacy variables
	Variables.varDefine('tournament_parent_name', Variables.varDefault('tournament_parentname', ''))
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype', ''))

	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate', ''))

	Variables.varDefine('date', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate', ''))

	--headtohead option
	Variables.varDefine('tournament_headtohead', args.headtohead)
	Variables.varDefine('headtohead', args.headtohead)

	-- tournament mode (1v1 or team)
	BasicHiddenDataBox:checkAndAssign('tournament_mode', args.mode, queryResult.extradata.mode)

	--gamemode
	BasicHiddenDataBox:checkAndAssign('tournament_gamemode', args.gamemode, queryResult.gamemode)
end

function CustomHiddenDataBox.validateTier(tierString, tierMode)
	if String.isEmpty(tierString) then
		return nil, nil
	end
	local warning
	local tierValue = tierString
	-- tier should be a number defining a tier
	if tierMode == TIER_MODE_TIERS and not Logic.isNumeric(tierValue) then
		tierValue = Tier.number[tierValue:lower()] or tierValue
	end
	local cleanedTierValue = Tier.text[tierMode][(tierValue):lower()]
	if not cleanedTierValue then
		cleanedTierValue = tierString
		warning = String.interpolate(
			INVALID_TIER_WARNING,
			{
				tierString = tierString,
				tierMode = tierMode == TIER_MODE_TYPES and 'Tiertype' or 'Tier',
			}
		)
	end

	tierValue = (tierMode == TIER_MODE_TYPES and cleanedTierValue) or tierValue or tierString

	return tierValue, warning
end

return Class.export(CustomHiddenDataBox)
