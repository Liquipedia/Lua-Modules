---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.game = Game.name{game = args.game, useDefault = false}

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	queryResult.extradata = queryResult.extradata or {}

	--custom stuff
	Variables.varDefine('headtohead', args.headtohead)

	if args.team_number then
		Variables.varDefine('is_team_tournament', 1)
		Variables.varDefine('participants_number', args.team_number)
	else
		Variables.varDefine(
			'participants_number',
			args.participants or args.participantsnumber or queryResult.participantsnumber
		)
		if Logic.readBool(args.teamevent) then
			Variables.varDefine('is_team_tournament', 1)
		end
	end

	-- Legacy Vars
	local startDate = Variables.varDefault('tournament_startdate', '')
	local endDate = Variables.varDefault('tournament_enddate', '')
	Variables.varDefine('date', endDate)
	Variables.varDefine('edate', endDate)
	Variables.varDefine('sdate', startDate)

	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername'))
	Variables.varDefine('tournament_abbreviation', Variables.varDefault('tournament_shortname'))
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
