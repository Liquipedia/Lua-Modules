---
-- @Liquipedia
-- page=Module:FindPlayersOnTeamFromPlacements
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')

local FindPlayersOnTeamFromPlacements = {}

---@param frame Frame
---@return Widget
function FindPlayersOnTeamFromPlacements.get(frame)
	local args = Arguments.getArgs(frame)
	assert(args.team, 'No player(s) specified')
	local team = mw.ext.TeamLiquidIntegration.resolve_redirect(args.team)

	local conditions = ConditionTree(BooleanOperator.any):add(Array.map(Array.range(1, 30), function(index)
		return ConditionNode(ColumnName('opponentplayers_p' .. index .. 'team'), Comparator.eq, team)
	end))

	local data = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		query = 'opponentplayers, date',
		order = 'date desc',
		limit = 5000,
	})

	local players = {}
	Array.forEach(data, function(item)
		local _ = Array.mapIndexes(function(index)
			local player = item.opponentplayers['p' .. index]
			if Logic.isEmpty(player) then
				return
			end
			local playerTeam = item.opponentplayers['p' .. index .. 'team']
			if playerTeam ~= team then
				return true
			end

			players[player] = players[player] or Table.merge(
				{date = item.date},
				Opponent.playerFromLpdbStruct(item.opponentplayers, index)
			)

			return true
		end)
	end)

	return UnorderedList{
		children = Array.map(Array.extractValues(players), function(player)
			return {				Link{link = player.pageName},
				' - displayName: ' .. player.displayName,
				' - flag: ' .. player.flag,
				' - faction: ' .. player.faction,
				' - last result from: ' .. player.date,
			}
		end)
	}
end

return FindPlayersOnTeamFromPlacements
