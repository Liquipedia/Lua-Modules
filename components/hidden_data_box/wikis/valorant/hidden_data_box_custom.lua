---
-- @Liquipedia
-- wiki=valorant
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Tier = mw.loadData('Module:Tier')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = require('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	args.liquipediatier = Tier.number[args.liquipediatier or '']
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	Variables.varDefine('tournament_parent_name', Variables.varDefault('tournament_parentname'))
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_icon_darkmode', Variables.varDefault('tournament_icondark'))
	Variables.varDefine('mode', Variables.varDefault('tournament_mode', 'team'))
	Variables.varDefine('female', queryResult.extradata.female or args.female and 'true' or 'false')
	BasicHiddenDataBox.checkAndAssign('patch', args.patch, queryResult.patch)
	BasicHiddenDataBox.checkAndAssign('tournament_riot_premier', queryResult.tournament_riot_premier, args.riotpremier)
end

return Class.export(CustomHiddenDataBox)
