---
-- @Liquipedia
-- wiki=mobilelegends
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

	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))

	BasicHiddenDataBox.checkAndAssign('tournament_patch', args.patch, queryResult.patch)
	BasicHiddenDataBox.checkAndAssign('tournament_publishertier', args['moonton-sponsored'], queryResult.publishertier)
end

return Class.export(CustomHiddenDataBox)
