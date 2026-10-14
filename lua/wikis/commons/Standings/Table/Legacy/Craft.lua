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

---Adaptor for the swiss tables of Module:GroupTableLeague/Starcraft/next
local StandingTableLegacyCraft = {}

-- Tournaments starting before this date keep the GroupTableLeague default tiebreakers
local UPDATED_DEFAULT_TIEBREAKERS_DATE = '2022-03-20'

---Common local Module:GroupTableLeague on starcraft, starcraft2, stormgate and warcraft
---@param frame Frame
---@return Renderable
function StandingTableLegacyCraft.run(frame)
	return StandingTableLegacyNext.fromArgs(Arguments.getArgs(frame), {
		defaultTiebreakers = StandingTableLegacyCraft.defaultTiebreakers,
	})
end

---@param args table
---@return string[]
function StandingTableLegacyCraft.defaultTiebreakers(args)
	local startDate = Variables.varDefault('tournament_startdate')
	if startDate and startDate < UPDATED_DEFAULT_TIEBREAKERS_DATE then
		return StandingTableLegacyNext.defaultTiebreakers(args)
	end
	return Array.extend(
		Logic.readBool(args.show_p) and 'points' or nil,
		'matchscore',
		'gamescore',
		'ml.matchscore',
		'ml.gamescore'
	)
end

return StandingTableLegacyCraft
