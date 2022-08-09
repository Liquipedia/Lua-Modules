---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
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
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('tournament_tier', Tier.text[Variables.varDefault('tournament_liquipediatier', '')])
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_icon_dark', Variables.varDefault('tournament_icondark'))

	Variables.varDefine('match_featured_override', args.featured)
	Variables.varDefine('tournament_valve_major', args.valvemajor or args.valvetier == 'Major')
	Variables.varDefine('tournament_valve_tier', args.valvetier)
end

return Class.export(CustomHiddenDataBox)
