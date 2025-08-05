---
-- @Liquipedia
-- page=Module:HiddenDataBox/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local BasicHiddenDataBox = Lua.import('Module:HiddenDataBox')
local CustomHiddenDataBox = {}

---@param args table
---@return Html
function CustomHiddenDataBox.run(args)
	args = args or {}

	BasicHiddenDataBox.addCustomVariables = CustomHiddenDataBox.addCustomVariables

	return BasicHiddenDataBox.run(args)
end

---@param args table
---@param queryResult table
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
end

return Class.export(CustomHiddenDataBox, {exports = {'run'}})
