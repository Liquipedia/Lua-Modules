---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Variables = Lua.import('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomLeague = Lua.import('Module:Infobox/League/Custom') ---@type RocketleagueLeagueInfobox
local CustomHiddenDataBox = {}

---@param args table
---@return Widget
function CustomHiddenDataBox.run(args)
	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables
	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier'))
	Variables.varDefine('tournament_tier_type', Variables.varDefault('tournament_liquipediatiertype'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('tournament_ticker_name',
		Variables.varDefault('tournament_tickername', Variables.varDefault('tournament_name'))
	)
	Variables.varDefine('tournament_icon_dark', Variables.varDefault('tournament_icondark'))
	Variables.varDefine('tournament_parent_name', Variables.varDefault('tournament_parentname'))
	Variables.varDefine('showh2h', CustomLeague.parseShowHeadToHead(args))
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
