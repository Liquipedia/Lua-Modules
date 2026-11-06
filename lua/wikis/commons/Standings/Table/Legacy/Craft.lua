---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Craft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Variables = Lua.import('Module:Variables')

local StandingTableLegacyNext = Lua.import('Module:Standings/Table/Legacy/Next')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local WarningBox = Lua.import('Module:Widget/WarningBox')

---Adaptor for the swiss tables of Module:GroupTableLeague/Starcraft/next
local StandingTableLegacyCraft = {}

-- Tournaments starting before this date keep the GroupTableLeague default tiebreakers
local UPDATED_DEFAULT_TIEBREAKERS_DATE = '2022-03-20'

---Common local Module:GroupTableLeague on starcraft, starcraft2, stormgate and warcraft
---@param frame Frame
---@return Renderable
function StandingTableLegacyCraft.run(frame)
	local display = StandingTableLegacyNext.build(
		StandingTableLegacyCraft._checkTiebreakerMode(Arguments.getArgs(frame)),
		'group',
		{defaultTiebreakers = StandingTableLegacyCraft.defaultTiebreakers}
	)

	return Html.Fragment{children = {
		display,
		WarningBox{text = {
			'Template:GroupTableLeague is deprecated. Use ',
			Link{link = 'Template:GroupStandings'},
			' instead!',
		}}
	}}
end

-- pwb -lang:... replace -transcludes:GroupTableLeague -regex -summary:"Convert GTL" "\{\{[gG]roupTableLeague"
-- "{{subst:#invoke:Standings/Table/Legacy/Craft|convert|tableType=group|push=true|useCraftTiebreakers=..."
---@param frame Frame
---@return Renderable
function StandingTableLegacyCraft.convert(frame)
	return StandingTableLegacyNext.convertFromArgs(
		StandingTableLegacyCraft._checkTiebreakerMode(Arguments.getArgs(frame)),
		{defaultTiebreakers = StandingTableLegacyCraft.defaultTiebreakers}
	)
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
