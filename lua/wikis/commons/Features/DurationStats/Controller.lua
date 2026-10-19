---
-- @Liquipedia
-- page=Module:Features/DurationStats/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Games = Lua.import('Module:Features/DurationStats/Api/Games')
local Tournaments = Lua.import('Module:Features/DurationStats/Api/Tournaments')
local Conditions = Lua.import('Module:Features/DurationStats/Lib/Conditions')

local Html = Lua.import('Module:Widget/Html')
local DurationStatsTable = Lua.import('Module:Features/DurationStats/Components/Table')

local DEFAULT_LIMIT = 5

local Controller = {}

---@param frame Frame
---@return Renderable
function Controller.run(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit) or DEFAULT_LIMIT

	local spec = TournamentStructure.readMatchGroupsSpec(args)
		or Tournaments.getSpecFromTier(args)
		or TournamentStructure.currentPageSpec()
	local conditions = tostring(Conditions.build(spec, args.sdate, args.edate))

	return Html.Fragment{
		children = {
			DurationStatsTable{
				title = 'Shortest Games',
				entries = Controller._fetchEntries(conditions, limit, 'length asc'),
			},
			Html.Br{},
			DurationStatsTable{
				title = 'Longest Games',
				entries = Controller._fetchEntries(conditions, limit, 'length desc'),
			},
		},
	}
end

---@private
---@param conditions string
---@param limit integer
---@param order string
---@return DurationStatsEntry[]
function Controller._fetchEntries(conditions, limit, order)
	return Array.map(Games.fetch(conditions, limit, order), function(game)
		return {game = game, match = Games.fetchMatch(game.match2id)}
	end)
end

return Controller
