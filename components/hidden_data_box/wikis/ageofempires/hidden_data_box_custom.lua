---
-- @Liquipedia
-- wiki=ageofempires
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

return Class.export(CustomHiddenDataBox)
