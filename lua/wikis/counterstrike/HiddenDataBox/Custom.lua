---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local HiddenMatches = Lua.import('Module:HiddenMatchDetermination', {loadData = true})
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')
local Variables = Lua.import('Module:Variables')

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

	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate'))

	local tier = Tier.toName(Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tier', tier)
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_icon_darkmode', Variables.varDefault('tournament_icondark'))

	Variables.varDefine('match_featured_override', args.featured)
	BasicHiddenDataBox.checkAndAssign('tournament_valve_tier', args.publishertier, queryResult.publishertier)

	Variables.varDefine('match_hidden', tostring(
		Logic.readBool(args.hidden)
		or Table.includes(HiddenMatches, Variables.varDefault('tournament_name'))
	))

	Variables.varDefine('tournament_subpage', 'true')
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
