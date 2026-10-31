---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Tournament = Lua.import('Module:Tournament')

local InputParser = Lua.import('Module:Features/TournamentAppearances/Lib/Parse')
local Types = Lua.import('Module:Features/TournamentAppearances/Types')

local TournamentAppearancesTable = Lua.import('Module:Features/TournamentAppearances/Components/Table')

local Controller = {}

---@param frame Frame
---@return Renderable
function Controller.execute(frame)
	local args = Arguments.getArgs(frame)
	local config = InputParser.readConfig(args)

	local tournaments = Array.reverse(Tournament.getAllTournaments(InputParser.readTournamentConditionInputs(config)))

	if Logic.isEmpty(tournaments) then
		return Types.NO_RESULTS_MESSAGE
	end

	local pageNames = Array.map(tournaments, Operator.property('pageName'))
	-- todo: port this into api + parsing parts
	local players = self:_fetchPlayers(pageNames)

	if not players then
		return Types.NO_RESULTS_MESSAGE
	end

	return TournamentAppearancesTable{
		tournaments = tournaments,
		players = players,
		config = config,
	}
end

return Controller
