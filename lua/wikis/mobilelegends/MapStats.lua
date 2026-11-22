---
-- @Liquipedia
-- page=Module:MapStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Arguments = Lua.import('Module:Arguments')
local Logic = Lua.import('Module:Logic')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')
local VodLink = Lua.import('Module:VodLink')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local MapMode = Lua.import('Module:MapMode')

local DEFAULT_LIMIT = 100
local BATCH_SIZE = 100
local MAX_BATCHES = 100

---@class MapStatsEntry
---@field pagename string
---@field date string?
---@field stageName string
---@field gameNumber integer
---@field length string?
---@field vod string?
---@field winner standardOpponent
---@field loser standardOpponent

---@class MapStatsHit
---@field match2id string
---@field gameNumbers integer[]

local MapStats = {}

---@param frame Frame
---@return Renderable
function MapStats.run(frame)
	local args = Arguments.getArgs(frame)

	local modeKey = MapMode.getKey(args.mode)
	assert(modeKey, 'Unknown MapMode: ' .. (args.mode or ''))

	return MapStats._display(MapStats._fetchEntries(modeKey, tonumber(args.limit) or DEFAULT_LIMIT))
end

---Same logic as the match ticker (Module:Widget/Match/Card): the inherited header of the match if it has one,
---otherwise the section of the match (or its matchsection).
---@param match MatchGroupUtilMatch
---@return string
function MapStats._getStageName(match)
	local inheritedHeader = match.bracketData and match.bracketData.inheritedHeader

	return (match.section ~= DEFAULT_STAGE and match.section)
		or (match.extradata or {}).matchsection
		or inheritedHeader
		or 'Results'
end

---Returns the winner and the loser of a game, given the opponent index of the winner.
---@param match MatchGroupUtilMatch
---@param gameWinner string|number|nil
---@return standardOpponent
---@return standardOpponent
function MapStats._getWinnerAndLoser(match, gameWinner)
	local winnerIndex = tonumber(gameWinner)
	if winnerIndex ~= 1 and winnerIndex ~= 2 then
		winnerIndex = 1
	end

	return match.opponents[winnerIndex] or Opponent.tbd(Opponent.team),
		match.opponents[3 - winnerIndex] or Opponent.tbd(Opponent.team)
end

---@param modeKey string
---@param limit integer
---@return MapStatsEntry[]
function MapStats._fetchEntries(modeKey, limit)
	local hits = MapStats._findHits(modeKey, limit)
	if #hits == 0 then
		return {}
	end

	local records = MapStats._fetchRecords(hits)

	---@type MapStatsEntry[]
	local entries = {}
	Array.forEach(hits, function(hit)
		local record = records[hit.match2id]
		if record then
			MapStats._collectEntries(record, hit.gameNumbers, entries)
		end
	end)

	return entries
end

---Scans matches newest first with a minimal field list and remembers which games use the mode.
---@param modeKey string
---@param limit integer
---@return MapStatsHit[]
function MapStats._findHits(modeKey, limit)
	local batchSize = math.min(BATCH_SIZE, math.max(limit * 3, 20))
	
	local conditions = tostring(ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('finished'), Comparator.eq, 1),
	})

	---@type MapStatsHit[]
	local hits = {}
	local gameCount = 0

	for batch = 0, MAX_BATCHES - 1 do
		local records = mw.ext.LiquipediaDB.lpdb('match2', {
			conditions = conditions,
			query = 'match2id, match2games',
			order = 'date desc',
			limit = batchSize,
			offset = batch * batchSize,
		})

		Array.forEach(records, function(record)
			local games = record.match2games or {}
			local gameNumbers = {}
			-- newest game of a match first
			for gameNumber = #games, 1, -1 do
				if gameCount + #gameNumbers < limit
					and MapMode.getKey((games[gameNumber].extradata or {}).mapmode) == modeKey then
					table.insert(gameNumbers, gameNumber)
				end
			end
			if #gameNumbers > 0 then
				gameCount = gameCount + #gameNumbers
				table.insert(hits, {match2id = record.match2id, gameNumbers = gameNumbers})
			end
		end)

		if gameCount >= limit or #records < batchSize then
			break
		end
	end

	return hits
end

---Fetches the full records of the matches that were hit, in a single query.
---@param hits MapStatsHit[]
---@return table<string, table>
function MapStats._fetchRecords(hits)
	local conditions = tostring(ConditionTree(BooleanOperator.any):add(
		Array.map(hits, function(hit)
			return ConditionNode(ColumnName('match2id'), Comparator.eq, hit.match2id)
		end)
	))

	local records = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = conditions,
		limit = #hits,
	})

	---@type table<string, table>
	local byId = {}
	Array.forEach(records, function(record)
		byId[record.match2id] = record
	end)
	return byId
end

---@param record table
---@param gameNumbers integer[]
---@param entries MapStatsEntry[]
function MapStats._collectEntries(record, gameNumbers, entries)
	local games = record.match2games or {}
	local match = MatchGroupUtil.matchFromRecord(record)
	local stageName = MapStats._getStageName(match)

	Array.forEach(gameNumbers, function(gameNumber)
		local game = games[gameNumber]
		local winner, loser = MapStats._getWinnerAndLoser(match, game.winner)
		table.insert(entries, {
			pagename = record.pagename,
			date = Logic.emptyOr(game.date, record.date),
			stageName = stageName,
			gameNumber = gameNumber,
			length = Logic.nilIfEmpty(game.length),
			vod = Logic.nilIfEmpty(game.vod),
			winner = winner,
			loser = loser,
		})
	end)
end

---@param opponent standardOpponent
---@return Renderable
function MapStats._opponentDisplay(opponent)
	return OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'hybrid'}
end

---@param entry MapStatsEntry
---@return Renderable
function MapStats._vodDisplay(entry)
	if not entry.vod then
		return ''
	end
	return tostring(VodLink.display{vod = entry.vod, gamenum = entry.gameNumber})
end

---@param entries MapStatsEntry[]
---@return Widget
function MapStats._display(entries)
	return TableWidgets.Table{
		sortable = true,
		columns = {
			{align = 'left'},
			{align = 'left'},
			{align = 'center'},
			{align = 'left'},
			{align = 'left'},
			{align = 'center'},
			{align = 'center'},
		},
		children = {
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = {
						TableWidgets.CellHeader{children = 'Date'},
						TableWidgets.CellHeader{children = 'Stage'},
						TableWidgets.CellHeader{children = 'Game #'},
						TableWidgets.CellHeader{children = 'Winner'},
						TableWidgets.CellHeader{children = 'Loser'},
						TableWidgets.CellHeader{children = 'Duration'},
						TableWidgets.CellHeader{children = 'VOD'},
					},
				},
			},
			TableWidgets.TableBody{
				children = Array.map(entries, function(entry)
					return TableWidgets.Row{
						children = {
							TableWidgets.Cell{children = string.sub(entry.date or '', 1, 10)},
							TableWidgets.Cell{children = Link{
								link = entry.pagename,
								children = entry.stageName,
							}},
							TableWidgets.Cell{children = entry.gameNumber},
							TableWidgets.Cell{children = MapStats._opponentDisplay(entry.winner)},
							TableWidgets.Cell{children = MapStats._opponentDisplay(entry.loser)},
							TableWidgets.Cell{children = Logic.emptyOr(entry.length, '-')},
							TableWidgets.Cell{children = MapStats._vodDisplay(entry)},
						},
					}
				end),
			},
		},
	}
end

return MapStats
