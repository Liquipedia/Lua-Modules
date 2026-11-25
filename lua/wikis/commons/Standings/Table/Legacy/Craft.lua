---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Craft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Timezone = Lua.import('Module:Timezone')
local Variables = Lua.import('Module:Variables')

local StandingTableLegacyNext = Lua.import('Module:Standings/Table/Legacy/Next')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WarningBox = Lua.import('Module:Widget/WarningBox')

---Adaptor for the swiss tables of Module:GroupTableLeague/Starcraft/next
local StandingTableLegacyCraft = {}

-- Tournaments starting before this date keep the GroupTableLeague default tiebreakers
local UPDATED_DEFAULT_TIEBREAKERS_DATE = '2022-03-20'

-- they don't have any effect, but we should keep them alive as arguments during conversion runs
local EXTRA_ARGUMENTS = {
	'preview',
	'interview',
	'review',
	'lrthread',
	'h2h',
	'vod',
	'recap',
	'date',
	'twitch',
	'youtube',
	'kick',
	'afreeca',
	'bilibili',
	'cc',
	'dailymotion',
	'douyu',
	'facebook',
	'huomao',
	'huya',
	'loco',
	'mildom',
	'nimo',
	'tl',
	'trovo',
	'stream',
}

---Common local Module:GroupTableLeague on starcraft, starcraft2, stormgate and warcraft
---@param frame Frame
---@return Renderable
function StandingTableLegacyCraft.run(frame)
	local args = Arguments.getArgs(frame)

	local display = StandingTableLegacyNext.build(
		StandingTableLegacyCraft._checkTiebreakerMode(args),
		'group',
		{defaultTiebreakers = StandingTableLegacyCraft.defaultTiebreakers}
	)

	local timestamp = DateExt.readTimestampOrNil(args.date)
	if timestamp then
		Variables.varDefine('match_date', DateExt.formatTimestamp('Y-m-d H:i:s', timestamp))
	end

	Variables.varDefine('matchListIsCollapsed', 1)

	return Html.Fragment{children = {
		WarningBox{text = {
			'Template:GroupTableLeague is deprecated. Use ',
			Link{link = 'Template:GroupStandings'},
			' instead!',
		}},
		display,
	}}
end

-- pwb -lang:... replace -transcludes:GroupTableLeague -regex -summary:"Convert GTL" "\{\{[gG]roupTableLeague"
-- "{{subst:#invoke:Standings/Table/Legacy/Craft|convert|tableType=group|push=true|useCraftTiebreakers=..."
---@param frame Frame
---@return Renderable
function StandingTableLegacyCraft.convert(frame)
	local args = Arguments.getArgs(frame)

	local extraArgs = Table.filterByKey(args, function(key)
		local baseKey = string.gsub(key, '%d+$', '')
		return Table.includes(EXTRA_ARGUMENTS, baseKey)
	end)

	---@type Renderable
	local varCode = '{{CollapseBelowMatchlists|true}}'
		.. StandingTableLegacyCraft.getMatchDateVar(args.date)
	if not Logic.readBool(args.push) then
		varCode = Html.Pre{children = varCode}
	end

	return Html.Fragment{children = {
		varCode,
		StandingTableLegacyNext.convertFromArgs(
			StandingTableLegacyCraft._checkTiebreakerMode(args),
			{
				defaultTiebreakers = StandingTableLegacyCraft.defaultTiebreakers,
				extraArgs = extraArgs,
			}
		),
	}}
end

---@param date string?
---@return string
function StandingTableLegacyCraft.getMatchDateVar(date)
	if Logic.isEmpty(date) then
		return ''
	end
	---@cast date -nil

	-- workaround for date template not getting parsed with (outer) subst calls
	local timezone = date:match('%{%{%s*[aA]bbr/(.+)%}%}')
	if Logic.isNotEmpty(timezone) then
		local withoutTimezone = date:gsub('%{%{%s*[aA]bbr/.+%}%}', '')
		date = withoutTimezone .. Timezone.getTimezoneString{timezone = timezone}
	end

	local timestamp = DateExt.readTimestampOrNil(date)
	if not timestamp then
		return ''
	end

	return '{{SetMatchDateVariable|date=' .. DateExt.formatTimestamp('Y-m-d H:i:s', timestamp) .. '}}'
end

---@param args table
---@return table
function StandingTableLegacyCraft._checkTiebreakerMode(args)
	-- wikivars are not available when doing subst bot runs
	-- hence need to find ways to process them without wiki vars accordingly
	args.useCraftTiebreakers = Logic.readBoolOrNil(args.useCraftTiebreakers)
	if args.useCraftTiebreakers ~= nil then
		return args
	end

	local startDate = Variables.varDefault('tournament_startdate')
	if startDate and startDate < UPDATED_DEFAULT_TIEBREAKERS_DATE then
		return args
	end

	args.useCraftTiebreakers = true

	return  args
end

---@param args table
---@return string[]
function StandingTableLegacyCraft.defaultTiebreakers(args)
	if not args.useCraftTiebreakers then
		return StandingTableLegacyNext.defaultTiebreakers(args)
	end

	-- to be able to filter them for conversion bot runs (with subst wiki vars are not available)
	mw.ext.TeamLiquidIntegration.add_category('GTL wrapper with craft-specific default tiebreakers')

	return Array.extend(
		Logic.readBool(args.show_p) and 'points' or nil,
		'matchscore',
		'gamescore',
		'ml.matchscore',
		'ml.gamescore'
	)
end

return StandingTableLegacyCraft
