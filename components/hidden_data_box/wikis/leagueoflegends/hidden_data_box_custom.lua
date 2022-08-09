---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = require('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))

	BasicHiddenDataBox.checkAndAssign('patch', args.patch, queryResult.patch)
	BasicHiddenDataBox.checkAndAssign(
		'tournament_publishertier',
		Logic.readBool(args.riotpremier) and '1' or nil,
		queryResult.publishertier
	)
	BasicHiddenDataBox.checkAndAssign(
		'tournament_riot_premier',
		args.riotpremier,
		queryResult.extradata['is riot premier']
	)
	BasicHiddenDataBox.checkAndAssign(
		'tournament_publisher_major',
		args.riotpremier,
		queryResult.extradata['is riot premier']
	)
end

return Class.export(CustomHiddenDataBox)
