---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_parent_name', queryResult.name or '')

	local endDate = Variables.varDefault('tournament_enddate')
	local startDate = Variables.varDefault('tournament_startdate')
	if startDate == endDate then
		Variables.varDefine('date', endDate)
	else
		Variables.varDefine('edate', endDate)
		Variables.varDefine('sdate', startDate)
	end
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
