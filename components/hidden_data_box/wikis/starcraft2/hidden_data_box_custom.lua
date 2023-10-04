---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox', {requireDevIfEnabled = true})
local CustomHiddenDataBox = {}

---@param args table
---@return string
function CustomHiddenDataBox.run(args)
	args = args or {}
	args.game = Game.name{game = args.game}

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	queryResult.extradata = queryResult.extradata or {}

	--custom stuff
	Variables.varDefine('headtohead', args.headtohead)
	args.featured = args.featured or args.publishertier
	args.featured = Logic.readBool(args.featured) and tostring(Logic.readBool(args.featured)) or nil
	BasicHiddenDataBox.checkAndAssign(
		'tournament_publishertier',
		args.featured,
		queryResult.publishertier
	)
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
			startdate = Variables.varDefault('tournament_startdate', '1970-01-01'),
			enddate = Variables.varDefault('tournament_enddate', '1970-01-01'),
			sortdate = Variables.varDefault('tournament_enddate', '1970-01-01'),
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

return Class.export(CustomHiddenDataBox)
