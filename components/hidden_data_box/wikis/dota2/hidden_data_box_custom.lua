---
-- @Liquipedia
-- wiki=dota2
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = require('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	queryResult.extradata = queryResult.extradata or {}

	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_icon_dark', Variables.varDefault('tournament_icondark'))
	Variables.varDefine('tournament_parent_page', Variables.varDefault('tournament_parent'))

	BasicHiddenDataBox.checkAndAssign('tournament_patch', args.patch, queryResult.patch)
	BasicHiddenDataBox.checkAndAssign('tournament_valve_premier', args.valvepremier, queryResult.extradata.valvepremier)
	BasicHiddenDataBox.checkAndAssign('tournament_publishertier', args.pctier, queryResult.publishertier)
	BasicHiddenDataBox.checkAndAssign('tournament_pro_circuit_tier', args.pctier, queryResult.publishertier)
end

return Class.export(CustomHiddenDataBox)
