---
-- @Liquipedia
-- page=Module:TournamentPlayerStats/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Calculator = Lua.import('Module:TournamentPlayerStats/Calculator')
local PlayerStatsTable = Lua.import('Module:Widget/TournamentPlayerStats/Table')

local TournamentPlayerStatsDisplay = {}

---@param frame Frame
---@return Renderable?
function TournamentPlayerStatsDisplay.fromTemplate(frame)
	local players = Calculator.getData(Arguments.getArgs(frame)).players

	if not players or #players == 0 then
		return nil
	end

	return PlayerStatsTable{players = players}
end

return TournamentPlayerStatsDisplay
