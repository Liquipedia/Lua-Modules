---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox', {requireDevIfEnabled = true})
local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	args = args or {}
	args.liquipediatier = args.liquipediatier and Tier.toNumber(args.liquipediatier) or args.liquipediatier

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate'))

	local tier = Tier.toName(Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_icon_darkmode', Variables.varDefault('tournament_icondark'))

	Variables.varDefine('match_featured_override', args.featured)
	Variables.varDefine('tournament_valve_major', args.valvemajor or (args.valvetier == 'Major' and 'true') or 'false')
	BasicHiddenDataBox.checkAndAssign('tournament_valve_tier', args.valvetier, queryResult.publishertier)
end

return Class.export(CustomHiddenDataBox)
