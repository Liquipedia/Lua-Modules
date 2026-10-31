---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local InputParser = Lua.import('Module:Features/TournamentAppearances/Lib/ParseInput')
local FetchPlayers = Lua.import('Module:Features/TournamentAppearances/Api/FetchPlayers')
local FetchTournaments = Lua.import('Module:Features/TournamentAppearances/Api/FetchTournaments')
local ParseQueried = Lua.import('Module:Features/TournamentAppearances/Lib/ParseQueried')
local Types = Lua.import('Module:Features/TournamentAppearances/Types')

local TournamentAppearancesTable = Lua.import('Module:Features/TournamentAppearances/Components/Table')

local Controller = {}

---@param frame Frame
---@return Renderable
function Controller.execute(frame)
	local args = Arguments.getArgs(frame)
	local config = InputParser.readConfig(args)

	local tournaments = Array.reverse(FetchTournaments.run(config))

	if Logic.isEmpty(tournaments) then
		return Types.NO_RESULTS_MESSAGE
	end

	-- todo: support opponent case
	local players = FetchPlayers.run{
		pageNames = Array.map(tournaments, Operator.property('pageName')),
		config = config,
		parsePlayersFromPlacement = FnUtil.curry(ParseQueried.fromPlacement, config),
	}

	if Logic.isEmpty(players) then
		return Types.NO_RESULTS_MESSAGE
	end

	if config.restrictToPlayersParticipatingIn then
		players = Array.filter(players, function(player)
			return player.extradata.results[config.restrictToPlayersParticipatingIn]
		end)
	end

	players = Array.sortBy(players, FnUtil.identity, ParseQueried.sort)

	return TournamentAppearancesTable{
		tournaments = tournaments,
		players = players,
		config = config,
	}
end

return Controller
