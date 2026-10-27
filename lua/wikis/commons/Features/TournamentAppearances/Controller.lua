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

local TournamentAppearancesHeader = Lua.import('Module:Features/TournamentAppearances/Components/Header')
local TournamentAppearancesRow = Lua.import('Module:Features/TournamentAppearances/Components/Row')

-- to be kicked once done
local Legacy = Lua.import('Module:PlayerTournamentAppearances')

local Controller = {}

---@param frame Frame
---@return Renderable
function Controller.execute(frame)
	-- kick this if once done, needed for step wise testing
	if true then
		return Legacy.run(frame)
	end

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

	local limit = math.min(config.limit or #players, #players)

	-- todo: move this to component
	return TableWidgets.Table{
		sortable = true,
		children = WidgetUtil.collect(
			TournamentAppearancesHeader{
				tournaments = tournaments,
				config = config,
			},
			TableWidgets.TableBody{
				children = Array.mapRange(1, limit, function(playerIndex)
					TournamentAppearancesRow{
						tournaments = tournaments,
						player = players[playerIndex],
						config = config
					}
				end)
			}
		),
		-- todo: port this
		footer = self:_buildQueryLink()
	}
end

return Controller
