---
-- @Liquipedia
-- page=Module:TeamStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MathUtil = Lua.import('Module:MathUtil')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Set = Lua.import('Module:Set')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TeamStatsRecord
---@field wins integer
---@field losses integer

---@class TeamStatsMap
---@field total TeamStatsRecord
---@field ownPick TeamStatsRecord
---@field opponentPick TeamStatsRecord
---@field decider TeamStatsRecord

---@class TeamStatsOpponent
---@field opponent standardOpponent
---@field maps table<string, TeamStatsMap>

local TeamStats = {}

local DASH = '–'

local PICK_TYPES = {
	{key = 'ownPick', short = 'own', long = 'on own pick'},
	{key = 'opponentPick', short = 'opp', long = 'on opponent pick'},
	{key = 'decider', short = 'dec', long = 'as decider'},
}

local LEGEND = Html.I{children = {
	'Each cell: wins-losses (win rate) on that map, then the split: ',
	Html.B{children = 'own'},
	' = on their own pick, ',
	Html.B{children = 'opp'},
	" = on the opponent's pick, ",
	Html.B{children = 'dec'},
	' = as decider. Hover a cell for details.',
}}

---@param frame Frame
---@return Renderable
function TeamStats.run(frame)
	local args = Arguments.getArgs(frame)
	local opponents = TeamStats.collect(args)

	if Table.isEmpty(opponents) then
		return Html.I{children = 'No map veto data found for this tournament.'}
	end

	return TeamStats.Overview{opponents = opponents}
end

-- Data

---@return TeamStatsRecord
local function newRecord()
	return {wins = 0, losses = 0}
end

---@param record TeamStatsRecord
---@return integer
local function gamesPlayed(record)
	return record.wins + record.losses
end

---@param entry TeamStatsOpponent
---@param map string
---@return TeamStatsMap
local function getMap(entry, map)
	if not entry.maps[map] then
		entry.maps[map] = {
			total = newRecord(),
			ownPick = newRecord(),
			opponentPick = newRecord(),
			decider = newRecord(),
		}
	end
	return entry.maps[map]
end

---@param args table
---@return TeamStatsOpponent[]
function TeamStats.collect(args)
	local spec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()

	---@type TeamStatsOpponent[]
	local opponents = {}

	---@param record table?
	---@return TeamStatsOpponent?
	local function getOpponent(record)
		if not record then
			return
		end
		local opponent = Opponent.fromMatch2Record(record)
		if Opponent.isTbd(opponent) then
			return
		end
		local entry = Array.find(opponents, function(existing)
			return Opponent.same(existing.opponent, opponent)
		end)
		if not entry then
			entry = {opponent = opponent, maps = {}}
			table.insert(opponents, entry)
		end
		return entry
	end

	Lpdb.executeMassQuery('match2', {
		conditions = tostring(TournamentStructure.getMatch2Filter(spec)),
		query = 'extradata, match2opponents, match2games',
		order = 'date asc',
	}, function(match)
		local vetoes = (match.extradata or {}).mapveto
		if type(vetoes) ~= 'table' or Logic.isEmpty(vetoes) then
			return
		end
		local pickedBy = TeamStats._getPickers(vetoes)

		Array.forEach(match.match2opponents or {}, function(record, opponentIndex)
			local entry = getOpponent(record)
			if entry then
				TeamStats._addGames(entry, match.match2games or {}, opponentIndex, pickedBy)
			end
		end)
	end)

	return opponents
end

--- Returns which opponent (1 or 2) picked each map of the veto.
---@param vetoes table[]
---@return table<string, integer>
function TeamStats._getPickers(vetoes)
	local pickedBy = {}
	Array.forEach(vetoes, function(veto)
		if veto.type ~= 'pick' then
			return
		end
		Array.forEach({1, 2}, function(opponentIndex)
			local map = veto['team' .. opponentIndex]
			if Logic.isNotEmpty(map) then
				pickedBy[map] = opponentIndex
			end
		end)
	end)
	return pickedBy
end

---@param entry TeamStatsOpponent
---@param games table[]
---@param opponentIndex integer
---@param pickedBy table<string, integer>
function TeamStats._addGames(entry, games, opponentIndex, pickedBy)
	Array.forEach(games, function(game)
		local winner = tonumber(game.winner)
		if Logic.isEmpty(game.map) or (winner ~= 1 and winner ~= 2) then
			return
		end

		local result = winner == opponentIndex and 'wins' or 'losses'
		local picker = pickedBy[game.map]
		local pickType = 'decider'
		if picker then
			pickType = picker == opponentIndex and 'ownPick' or 'opponentPick'
		end

		local mapStats = getMap(entry, game.map)
		mapStats.total[result] = mapStats.total[result] + 1
		mapStats[pickType][result] = mapStats[pickType][result] + 1
	end)
end

-- Display

---@param record TeamStatsRecord
---@return string
local function formatRecord(record)
	return record.wins .. '-' .. record.losses
end

---@param record TeamStatsRecord
---@return number # between 0 and 1
local function winRate(record)
	return record.wins / gamesPlayed(record)
end

---@param entry TeamStatsOpponent
---@return TeamStatsRecord
local function totalRecord(entry)
	local total = newRecord()
	for _, mapStats in pairs(entry.maps) do
		total.wins = total.wins + mapStats.total.wins
		total.losses = total.losses + mapStats.total.losses
	end
	return total
end

--- Every map at least one opponent played, in alphabetical order.
---@param opponents TeamStatsOpponent[]
---@return string[]
local function playedMaps(opponents)
	local maps = Set()
	for _, entry in ipairs(opponents) do
		for map, mapStats in pairs(entry.maps) do
			if gamesPlayed(mapStats.total) > 0 then
				maps:add(map)
			end
		end
	end
	local sortedMaps = maps:toArray()
	table.sort(sortedMaps)
	return sortedMaps
end

---@param parts string[]
---@return Renderable?
local function smallLine(parts)
	if Logic.isEmpty(parts) then
		return nil
	end
	return Html.Div{
		css = {['font-size'] = '75%', opacity = '0.85'},
		children = table.concat(parts, ' · '),
	}
end

--- One cell: wins-losses and win rate on a map, then the own / opponent / decider split.
--- A plain Table2 cell (not wrapped in its own component), so the row applies the column settings to it.
---@param mapStats TeamStatsMap?
---@return Renderable
function TeamStats._mapCell(mapStats)
	if not mapStats or gamesPlayed(mapStats.total) == 0 then
		return TableWidgets.Cell{
			attributes = {['data-sort-value'] = -1},
			children = Html.Span{css = {opacity = '0.4'}, children = DASH},
		}
	end

	local total = mapStats.total
	local rate = winRate(total)
	local percentage = MathUtil.formatPercentage(rate)

	local splitTypes = Array.filter(PICK_TYPES, function(pickType)
		return gamesPlayed(mapStats[pickType.key]) > 0
	end)
	-- own / opp on one line, the decider on its own line below
	local pickSplit, deciderSplit = {}, {}
	Array.forEach(splitTypes, function(pickType)
		local label = pickType.short .. ' ' .. formatRecord(mapStats[pickType.key])
		table.insert(pickType.key == 'decider' and deciderSplit or pickSplit, label)
	end)
	local tooltip = Array.map(splitTypes, function(pickType)
		return formatRecord(mapStats[pickType.key]) .. ' ' .. pickType.long
	end)

	return TableWidgets.Cell{
		classes = {rate > 0.5 and 'bg-win' or rate < 0.5 and 'bg-down' or 'bg-draw'},
		attributes = {
			['data-sort-value'] = rate * 1000 + gamesPlayed(total),
			title = formatRecord(total) .. ' (' .. percentage .. '): ' .. table.concat(tooltip, ', '),
		},
		children = WidgetUtil.collect(
			Html.Div{children = {
				Html.B{children = formatRecord(total)},
				Html.Span{css = {['font-size'] = '85%', opacity = '0.8'}, children = ' (' .. percentage .. ')'},
			}},
			smallLine(pickSplit),
			smallLine(deciderSplit)
		),
	}
end

--- One row per opponent, one column per map.
---@param props {opponents: TeamStatsOpponent[]}
---@return Renderable
local function Overview(props)
	local entries = Array.copy(props.opponents)
	table.sort(entries, function(a, b)
		local totalA, totalB = totalRecord(a), totalRecord(b)
		if totalA.wins ~= totalB.wins then
			return totalA.wins > totalB.wins
		end
		if totalA.losses ~= totalB.losses then
			return totalA.losses < totalB.losses
		end
		return Opponent.toName(a.opponent) < Opponent.toName(b.opponent)
	end)
	local maps = playedMaps(props.opponents)

	return TableWidgets.Table{
		sortable = true,
		columns = WidgetUtil.collect(
			{align = 'left'},
			Array.map(maps, function()
				-- a darker line between two maps, see Table2.scss
				return {align = 'center', classes = {'table2__cell--divider'}}
			end)
		),
		children = {
			TableWidgets.TableHeader{children = {
				TableWidgets.Row{children = WidgetUtil.collect(
					TableWidgets.CellHeader{children = 'Opponent'},
					Array.map(maps, function(map)
						return TableWidgets.CellHeader{children = Link{link = map, children = map}}
					end)
				)},
			}},
			TableWidgets.TableBody{children = Array.map(entries, function(entry)
				return TableWidgets.Row{children = WidgetUtil.collect(
					TableWidgets.Cell{children = OpponentDisplay.InlineOpponent{opponent = entry.opponent}},
					Array.map(maps, function(map)
						return TeamStats._mapCell(entry.maps[map])
					end)
				)}
			end)},
		},
		footer = LEGEND,
	}
end
TeamStats.Overview = Component.component(Overview)

return TeamStats
