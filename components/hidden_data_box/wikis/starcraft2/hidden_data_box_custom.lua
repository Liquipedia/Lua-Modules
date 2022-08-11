---
-- @Liquipedia
-- wiki=starcraft2
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
	args = args or {}
	args.participantGrabber = false

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	queryResult.extradata = queryResult.extradata or {}

	--legacy variables
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))
	Variables.varDefine('tournament_tiertype', Variables.varDefault('tournament_liquipediatiertype', ''))
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate', ''))
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername', ''))
	BasicHiddenDataBox.checkAndAssign(
		'tournament_abbreviation',
		args.abbreviation or args.shortname,
		queryResult.shortname
	)

	--custom stuff
	Variables.varDefine('headtohead', args.headtohead)
	BasicHiddenDataBox.checkAndAssign(
		'featured',
		args.featured,
		queryResult.extradata.featured
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
			tickername = Variables.varDefault('tournament_ticker_name'),
			shortname = Variables.varDefault('tournament_shortname', Variables.varDefault('tournament_abbreviation')),
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
