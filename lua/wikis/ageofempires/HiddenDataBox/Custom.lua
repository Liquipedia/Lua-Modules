---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
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
	queryResult.extradata = queryResult.extradata or {}

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

	Variables.varDefine('tournament_game', args.game or queryResult.game)

	--headtohead option
	Variables.varDefine('tournament_headtohead', args.headtohead)
	Variables.varDefine('headtohead', args.headtohead)

	-- tournament mode (1v1 or team)
	BasicHiddenDataBox.checkAndAssign('tournament_mode', args.mode, queryResult.extradata.mode)

	--gamemode
	BasicHiddenDataBox.checkAndAssign('tournament_gamemode', args.gamemode, queryResult.gamemode)

	--maps
	Variables.varDefine('tournament_maps', queryResult.maps)

	-- legacy variables, to be removed with match2
	local maps, failure = Json.parse(queryResult.maps)
	if not failure then
		for _, map in ipairs(maps) do
			Variables.varDefine('tournament_map_'.. (map.name or map.link), map.link)
		end
	end
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
