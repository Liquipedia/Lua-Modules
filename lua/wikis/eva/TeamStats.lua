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
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Table = Lua.import('Module:Table')
local TournamentStructure = Lua.import('Module:TournamentStructure')

---@class TeamStatsRecord
---@field wins integer
---@field losses integer

---@class TeamStatsMap
---@field total TeamStatsRecord
---@field ownPick TeamStatsRecord
---@field opponentPick TeamStatsRecord
---@field decider TeamStatsRecord

---@class TeamStatsTeam
---@field name string
---@field opponent standardOpponent
---@field maps table<string, TeamStatsMap>

local TeamStats = {}

local NO_DATA = "''No map veto data found for this tournament.''"
local DASH = '–'

local PICK_TYPES = {
	{key = 'ownPick', short = 'own', long = 'on own pick'},
	{key = 'opponentPick', short = 'opp', long = 'on opponent pick'},
	{key = 'decider', short = 'dec', long = 'as decider'},
}

local LEGEND = "''Each cell: wins-losses (win rate) on that map, then the split: "
	.. "'''own''' = on the team's own pick, '''opp''' = on the opponent's pick, "
	.. "'''dec''' = as decider. Hover a cell for details.''"

---@param frame Frame
---@return Html|string
function TeamStats.run(frame)
	local args = Arguments.getArgs(frame)
	local teams, maps = TeamStats.collect(args)

	if Table.isEmpty(teams) then
		return NO_DATA
	end

	return TeamStats.overviewTable(teams, maps)
end

-- Template:TeamStats calls the module with fn=MapsPlayed
TeamStats.MapsPlayed = TeamStats.run

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

---@param team TeamStatsTeam
---@param map string
---@return TeamStatsMap
local function getMap(team, map)
	if not team.maps[map] then
		team.maps[map] = {
			total = newRecord(),
			ownPick = newRecord(),
			opponentPick = newRecord(),
			decider = newRecord(),
		}
	end
	return team.maps[map]
end

---@param args table
---@return table<string, TeamStatsTeam> teams
---@return string[] maps
function TeamStats.collect(args)
	local spec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()

	---@type table<string, TeamStatsTeam>
	local teams = {}

	---@param record table?
	---@return TeamStatsTeam?
	local function getTeam(record)
		if not record or Logic.isEmpty(record.name) then
			return
		end
		local name = record.name:gsub('_', ' ')
		if not teams[name] then
			local opponent = Opponent.fromMatch2Record(record)
			if Opponent.isTbd(opponent) then
				return
			end
			teams[name] = {name = name, opponent = opponent, maps = {}}
		end
		return teams[name]
	end

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(TournamentStructure.getMatch2Filter(spec)),
		query = 'extradata, match2opponents, match2games',
		order = 'date asc',
		limit = 5000,
	})

	Array.forEach(matches, function(match)
		local vetoes = (match.extradata or {}).mapveto
		if type(vetoes) ~= 'table' or Logic.isEmpty(vetoes) then
			return
		end
		local pickedBy = TeamStats._getPickers(vetoes)

		for opponentIndex = 1, 2 do
			local team = getTeam(match.match2opponents[opponentIndex])
			if team then
				TeamStats._addGames(team, match.match2games or {}, opponentIndex, pickedBy)
			end
		end
	end)

	return teams, TeamStats._getMapOrder(spec, teams)
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
		for opponentIndex = 1, 2 do
			local map = veto['team' .. opponentIndex]
			if Logic.isNotEmpty(map) then
				pickedBy[map] = opponentIndex
			end
		end
	end)
	return pickedBy
end

---@param team TeamStatsTeam
---@param games table[]
---@param opponentIndex integer
---@param pickedBy table<string, integer>
function TeamStats._addGames(team, games, opponentIndex, pickedBy)
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

		local mapStats = getMap(team, game.map)
		mapStats.total[result] = mapStats.total[result] + 1
		mapStats[pickType][result] = mapStats[pickType][result] + 1
	end)
end

--- Map pool of the tournament (in infobox order), followed by any other played map in alphabetical order.
---@param spec table
---@param teams table<string, TeamStatsTeam>
---@return string[]
function TeamStats._getMapOrder(spec, teams)
	local maps = Array.parseCommaSeparatedString(TeamStats._fetchMapPool(spec), ';')

	local otherMaps = {}
	for _, team in pairs(teams) do
		for map, mapStats in pairs(team.maps) do
			if gamesPlayed(mapStats.total) > 0 and not Table.includes(maps, map) then
				otherMaps[map] = true
			end
		end
	end

	local sortedOtherMaps = Array.extractKeys(otherMaps)
	table.sort(sortedOtherMaps)
	return Array.extend(maps, sortedOtherMaps)
end

---@param spec table
---@return string?
function TeamStats._fetchMapPool(spec)
	local pageName = spec.pageNames and spec.pageNames[1]
	if type(pageName) == 'table' then
		pageName = pageName[1]
	end
	if Logic.isEmpty(pageName) then
		return nil
	end

	-- 'Tournament/Page#Section' -> 'Tournament/Page'
	pageName = pageName:gsub('#.*', ''):gsub(' ', '_')
	local tournament = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. pageName .. ']]',
		query = 'maps',
		limit = 1,
	})[1]
	return tournament and tournament.maps or nil
end

-- Display

---@param record TeamStatsRecord
---@return string
local function formatRecord(record)
	return record.wins .. '-' .. record.losses
end

---@param record TeamStatsRecord
---@return integer?
local function winRate(record)
	local played = gamesPlayed(record)
	if played == 0 then
		return nil
	end
	return math.floor(record.wins / played * 100 + 0.5)
end

---@param team TeamStatsTeam
---@return TeamStatsRecord
local function teamTotal(team)
	local total = newRecord()
	for _, mapStats in pairs(team.maps) do
		total.wins = total.wins + mapStats.total.wins
		total.losses = total.losses + mapStats.total.losses
	end
	return total
end

---@param opponent standardOpponent
---@return string
local function displayTeam(opponent)
	return tostring(OpponentDisplay.InlineOpponent{opponent = opponent})
end

---@param content string|number
---@return Html
local function headerCell(content)
	return mw.html.create('th'):css('white-space', 'nowrap'):wikitext(content)
end

---@param mapStats TeamStatsMap?
---@return Html
function TeamStats._mapCell(mapStats)
	local cell = mw.html.create('td')
		:css('text-align', 'center')
		:css('white-space', 'nowrap')

	if not mapStats or gamesPlayed(mapStats.total) == 0 then
		return cell
			:attr('data-sort-value', -1)
			:css('opacity', '0.4')
			:wikitext(DASH)
	end

	local total = mapStats.total
	local rate = winRate(total) --[[@as integer]]
	if rate > 50 then
		cell:addClass('bg-win')
	elseif rate < 50 then
		cell:addClass('bg-down')
	else
		cell:addClass('bg-draw')
	end

	local splitTypes = Array.filter(PICK_TYPES, function(pickType)
		return gamesPlayed(mapStats[pickType.key]) > 0
	end)
	local split = Array.map(splitTypes, function(pickType)
		return pickType.short .. ' ' .. formatRecord(mapStats[pickType.key])
	end)
	local tooltip = Array.map(splitTypes, function(pickType)
		return formatRecord(mapStats[pickType.key]) .. ' ' .. pickType.long
	end)

	return cell
		:attr('data-sort-value', rate * 1000 + gamesPlayed(total))
		:attr('title', formatRecord(total) .. ' (' .. rate .. '%): ' .. table.concat(tooltip, ', '))
		:tag('div')
			:tag('b'):wikitext(formatRecord(total)):done()
			:tag('span'):css('font-size', '85%'):css('opacity', '0.8'):wikitext(' (' .. rate .. '%)'):done()
			:done()
		:tag('div')
			:css('font-size', '75%')
			:css('opacity', '0.85')
			:wikitext(table.concat(split, ' · '))
			:done()
end

--- One row per team, one column per map.
---@param teams table<string, TeamStatsTeam>
---@param maps string[]
---@return Html
function TeamStats.overviewTable(teams, maps)
	local sortedTeams = Array.extractValues(teams)
	table.sort(sortedTeams, function(a, b)
		local totalA, totalB = teamTotal(a), teamTotal(b)
		if totalA.wins ~= totalB.wins then
			return totalA.wins > totalB.wins
		end
		if totalA.losses ~= totalB.losses then
			return totalA.losses < totalB.losses
		end
		return a.name < b.name
	end)

	local tbl = mw.html.create('table')
		:addClass('wikitable wikitable-bordered wikitable-striped sortable')

	local header = tbl:tag('tr'):node(headerCell('Team'))
	Array.forEach(maps, function(map)
		header:node(headerCell('[[' .. map .. ']]'))
	end)

	Array.forEach(sortedTeams, function(team)
		local row = tbl:tag('tr')
		row:tag('td'):css('white-space', 'nowrap'):wikitext(displayTeam(team.opponent))
		Array.forEach(maps, function(map)
			row:node(TeamStats._mapCell(team.maps[map]))
		end)
	end)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(tbl)
		:tag('div'):css('font-size', '85%'):css('opacity', '0.8'):wikitext(LEGEND):done()
end

return TeamStats
