---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox', {requireDevIfEnabled = true})
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
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))

	Variables.varDefine('tournament_mode', Variables.varDefault('tournament_mode', 'team'))
end

return Class.export(CustomHiddenDataBox)
