---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox', {requireDevIfEnabled = true})
local CustomHiddenDataBox = {}

function CustomHiddenDataBox.run(args)
	args = args or {}

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

function CustomHiddenDataBox.addCustomVariables(args, queryResult)
	queryResult.extradata = queryResult.extradata or {}

	--legacy variables
	Variables.varDefine('tournament_ticker_name', Variables.varDefault('tournament_tickername', ''))
	Variables.varDefine('tournament_tier', Variables.varDefault('tournament_liquipediatier', ''))

	-- legacy date variables
	Variables.varDefine('tournament_date', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_edate', Variables.varDefault('tournament_enddate', ''))
	Variables.varDefine('tournament_sdate', Variables.varDefault('tournament_startdate', ''))
	Variables.varDefine('sdate', Variables.varDefault('tournament_startdate'))
	Variables.varDefine('edate', Variables.varDefault('tournament_enddate'))
	Variables.varDefine('date', Variables.varDefault('tournament_enddate'))

	BasicHiddenDataBox.checkAndAssign(
		'tournament_icon_name',
		args.abbreviation and args.abbreviation:lower() or nil,
		queryResult.shortname
	)
	Variables.varDefine('tournament_icon_filename', Variables.varDefault('tournament_icon'))

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

	Variables.varDefine('environment', Variables.varDefault('tournament_type', ''))

	if args.starttime then
		Variables.varDefine('tournament_starttimeraw', Variables.varDefault('tournament_startdate', '') .. args.starttime)

		local startTime = Variables.varDefault('tournament_startdate', '') .. ' '
			.. args.starttime:gsub('<.*', '')

		Variables.varDefine('tournament_starttime', startTime)
		Variables.varDefine('start_time', startTime)
		local timeZone = args.starttime:match('data%-tz="(.-)"')
		if timeZone then
			Variables.varDefine('tournament_timezone', timeZone)
		end
	end

	--if specified also store in lpdb (custom for warcraft)
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
