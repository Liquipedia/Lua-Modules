---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Tier = require('Module:Tier/Custom')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.liquipediatier = Tier.toNumber(args.liquipediatier)

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate'))

	Variables.varDefine('tournament_link', Variables.varDefault('tournament_parent'))
	Variables.varDefine('series', Variables.varDefault('tournament_series'))
	Variables.varDefine('tournament_region', queryResult.extradata.region)
	Variables.varDefine('assumedpayout', queryResult.extradata.assumed_payout)
	Variables.varDefine('tournament_entrants', queryResult.participantsnumber)
	Variables.varDefine('tournament_mode', Variables.varDefault('tournament_mode', 'singles'))

	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))

	Variables.varDefine('tournament_subpage', 'true')
end

return Class.export(CustomHiddenDataBox)
