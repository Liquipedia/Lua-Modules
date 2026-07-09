---
-- @Liquipedia
-- page=Module:TournamentPlayerStats/Calculator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

---@class TournamentPlayerStats.RawRow
---@field name string
---@field games number?
---@field kills number?
---@field assists number?
---@field knocks number?
---@field damage number?
---@field damageTaken number?

---@class TournamentPlayerStats.PlacementEntry
---@field displayName string
---@field pageName string
---@field flag string?
---@field team string?

---@class TournamentPlayerStats.Player: standardPlayer
---@field games number?
---@field kills number?
---@field assists number?
---@field knocks number?
---@field damage number?
---@field damageTaken number?
---@field damageDiff number?

---@class TournamentPlayerStats.PlacementIndex
---@field byPage table<string, TournamentPlayerStats.PlacementEntry>

---@class TournamentPlayerStats.Data
---@field ids string[]
---@field players TournamentPlayerStats.Player[]

local TournamentPlayerStatsCalculator = {}

local DATAPOINT_TYPE = 'TournamentPlayerStats'

---@type string[]
local STAT_FIELDS = {
	'games',
	'kills',
	'assists',
	'knocks',
	'damage',
	'damageTaken',
}

---@type fun(name: string): string?
local getPageName = FnUtil.memoize(Page.pageifyLink)

---@param args table
---@return string
local function readTournamentPage(args)
	local tournament = assert(String.nilIfEmpty(args.tournament), 'TournamentPlayerStats: missing tournament')
	return Page.pageifyLink(tournament) or tournament
end

---@param args table
---@return string[]
local function readIds(args)
	return Array.extractValues(Table.filterByKey(args, function(key)
		return key:match('^id%d*$') ~= nil
	end))
end

---@param row any
---@return TournamentPlayerStats.RawRow?
local function rowFromInput(row)
	if type(row) ~= 'table' then
		return nil
	end

	local name = String.nilIfEmpty(row.name)
	if not name then
		return nil
	end

	return {
		name = name,
		games = tonumber(row.games),
		kills = tonumber(row.kills),
		assists = tonumber(row.assists),
		knocks = tonumber(row.knocks),
		damage = tonumber(row.damage),
		damageTaken = tonumber(row.damageTaken),
	}
end

---@param rawData string|table?
---@return TournamentPlayerStats.RawRow[]
local function readPlayers(rawData)
	local list = Json.parseStringified(rawData)
	if type(list) ~= 'table' then
		return {}
	end

	local rows = {}
	for _, item in ipairs(list) do
		local row = rowFromInput(item)
		if row then
			table.insert(rows, row)
		end
	end
	return rows
end

---@param frame Frame|table
function TournamentPlayerStatsCalculator.store(frame)
	local args = Arguments.getArgs(frame)

	if Lpdb.isStorageDisabled() then
		return
	end

	local id = assert(String.nilIfEmpty(args.id), 'TournamentPlayerStats: missing id')
	local tournamentPage = readTournamentPage(args)
	local players = readPlayers(Logic.emptyOr(args.players, args.data, args[1]))

	local objectname = 'tournament_player_stats_' .. id
	local data = {
		type = DATAPOINT_TYPE,
		name = id,
		information = tournamentPage,
		extradata = {
			players = players,
		},
	}

	mw.ext.LiquipediaDB.lpdb_datapoint(objectname, Json.stringifySubTables(data))

	return
end

---@param id string
---@return table?
local function fetchById(id)
	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('type'), Comparator.eq, DATAPOINT_TYPE),
			ConditionNode(ColumnName('name'), Comparator.eq, id),
		}

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(conditions),
		query = 'extradata, information',
		limit = 1,
	})
	return type(data) == 'table' and data[1] or nil
end

---@param tournamentPage string
---@return TournamentPlayerStats.PlacementIndex
local function buildPlacementIndex(tournamentPage)
	local index = {
		byPage = {},
	}

	local title = mw.title.new(tournamentPage)
	if not title then
		return index
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{
			ConditionNode(ColumnName('pagename'), Comparator.eq, title.text:gsub(' ', '_')),
			title.namespace ~= 0 and ConditionNode(ColumnName('namespace'), Comparator.eq, title.namespace) or nil,
		}

	local rows = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		query = 'opponentname, opponenttype, opponenttemplate, opponentplayers',
		limit = 5000,
	})

	if type(rows) == 'table' then
		Array.forEach(rows, function(row)
			if Logic.isEmpty(row.opponentplayers) then
				return
			end

			local opponent = Opponent.fromLpdbStruct(row)

			Array.forEach(opponent and opponent.players or {}, function(player)
				local pageName = Page.pageifyLink(player.pageName)
				if not pageName or index.byPage[pageName] then
					return
				end

				index.byPage[pageName] = {
					displayName = player.displayName,
					pageName = pageName,
					flag = player.flag,
					team = opponent.type == Opponent.team and opponent.template or player.team,
				}
			end)
		end)
	end

	return index
end

TournamentPlayerStatsCalculator.getPlacementIndex = FnUtil.memoize(buildPlacementIndex)

---@param raw TournamentPlayerStats.RawRow
---@param tournamentPage string
---@return TournamentPlayerStats.Player?
local function playerFromRow(raw, tournamentPage)
	local placementIndex = TournamentPlayerStatsCalculator.getPlacementIndex(tournamentPage)
	local pageName = getPageName(raw.name)
	local placementEntry = pageName and placementIndex.byPage[pageName] or nil

	pageName = (placementEntry and placementEntry.pageName) or pageName
	if not pageName then
		return nil
	end

	return {
		displayName = (placementEntry and placementEntry.displayName) or raw.name,
		pageName = pageName,
		flag = placementEntry and placementEntry.flag or nil,
		team = placementEntry and placementEntry.team or nil,
		games = raw.games,
		kills = raw.kills,
		assists = raw.assists,
		knocks = raw.knocks,
		damage = raw.damage,
		damageTaken = raw.damageTaken,
	}
end

---@param target TournamentPlayerStats.Player
---@param source TournamentPlayerStats.Player
local function mergePlayers(target, source)
	Array.forEach(STAT_FIELDS, function(field)
		target[field] = Operator.nilSafeAdd(target[field], source[field])
	end)

	target.pageName = target.pageName or source.pageName
	target.flag = target.flag or source.flag
	target.team = target.team or source.team
end

---@param args table
---@return TournamentPlayerStats.Data
function TournamentPlayerStatsCalculator.getData(args)
	local ids = readIds(args)

	---@type table<string, TournamentPlayerStats.Player>
	local playersByKey = {}

	Array.forEach(ids, function(id)
		local row = fetchById(id)
		if not row then
			return
		end

		local tournamentPage = row.information
		if not tournamentPage or type(tournamentPage) ~= 'string' then
			return
		end

		local storedPlayers = (row.extradata or {}).players or {}

		Array.forEach(storedPlayers, function(rawPlayer)
			local rawRow = rowFromInput(rawPlayer)
			if not rawRow then
				return
			end

			local player = playerFromRow(rawRow, tournamentPage)
			if not player then
				return
			end

			local key = player.pageName

			if not playersByKey[key] then
				playersByKey[key] = player
			else
				mergePlayers(playersByKey[key], player)
			end
		end)
	end)

	local players = Array.extractValues(playersByKey)

	Array.forEach(players, function(player)
		if player.damage and player.damageTaken then
			player.damageDiff = player.damage - player.damageTaken
		end
	end)

	Array.sortInPlaceBy(players, function(player) return player end, function(a, b)
		local teamA = String.nilIfEmpty(a.team)
		local teamB = String.nilIfEmpty(b.team)

		if (teamA == nil) ~= (teamB == nil) then
			return teamA ~= nil
		end

		if teamA and teamB and teamA:lower() ~= teamB:lower() then
			return teamA:lower() < teamB:lower()
		end

		local killsA = a.kills or 0
		local killsB = b.kills or 0
		return killsA > killsB
	end)

	return {
		ids = ids,
		players = players,
	}
end

return TournamentPlayerStatsCalculator
