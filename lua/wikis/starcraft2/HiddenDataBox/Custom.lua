---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.game = Game.toIdentifier{game = args.game, useDefault = false}

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

	--if specified also store in lpdb (custom for sc2)
	if Logic.readBool(args.storage) then
		local prizepool = CustomHiddenDataBox.cleanPrizePool(args.prizepool) or queryResult.prizepool
		local lpdbData = {
			name = Variables.varDefault('tournament_name'),
			tickername = Variables.varDefault('tournament_tickername'),
			shortname = Variables.varDefault('tournament_shortname'),
			icon = Variables.varDefault('tournament_icon'),
			icondark = Variables.varDefault('tournament_icon_dark'),
			series = mw.ext.TeamLiquidIntegration.resolve_redirect(Variables.varDefault('tournament_series', '')),
			game = string.lower(Variables.varDefault('tournament_game', '')),
			type = Variables.varDefault('tournament_type'),
			startdate = Variables.varDefault('tournament_startdate', DateExt.defaultDate),
			enddate = Variables.varDefault('tournament_enddate', DateExt.defaultDate),
			sortdate = Variables.varDefault('tournament_enddate', DateExt.defaultDate),
			liquipediatier = Variables.varDefault('tournament_liquipediatier'),
			liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
			status = Variables.varDefault('tournament_status'),
			participantsnumber = Variables.varDefault('participants_number'),
			location = queryResult.location,
			prizepool = prizepool,
		}
		mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. Variables.varDefault('tournament_name'), lpdbData)
	end
end

function CustomHiddenDataBox.cleanPrizePool(value)
	value = string.gsub(value or '', ',', '')
	value = string.gsub(value or '', '$', '')
	if value ~= '' then
		return value
	end
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
