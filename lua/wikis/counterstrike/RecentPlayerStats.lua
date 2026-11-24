---
-- @Liquipedia
-- page=Module:RecentPlayerStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Player statistics for an event
-- Ripped from valorant, data from NUSELO/OpenVRS
-- Contact Mischief/Finn about this module

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local MathUtil = Lua.import('Module:MathUtil')
local Namespace = Lua.import('Module:Namespace')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local ConditionTree = Condition.Tree
local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MONTH = DateExt.daysToSeconds(30.4375)
local NOT_PLAYED = 'notplayed'

-- Per-round stats that are weighted by rounds
local ROUND_WEIGHTED = {
	{'rating', 'roundsPlayed'},
	{'ratingT', 'roundsT'},
	{'ratingCt', 'roundsCt'},
	{'adr', 'roundsPlayed'},
	{'kast', 'roundsPlayed'},
	{'altSwing', 'roundsPlayed'},
	{'leverage', 'roundsPlayed'},
	{'ecoKpr', 'roundsPlayed'},
	{'ecoDpr', 'roundsPlayed'},
	{'ecoAdr', 'roundsPlayed'},
}

-- Counts turned into per round rates: summed
local PER_ROUND_COUNTS = {'kills', 'entryAttempts', 'awpKills', 'msl'}

---@class CounterstrikeRecentPlayerStatsData
---@field pageName string
---@field displayName string
---@field flag string?
---@field team string?
---@field maps integer
---@field kills integer
---@field deaths integer
---@field assists integer
---@field firstKills integer
---@field firstDeaths integer
---@field tradeKills integer
---@field tradeDeaths integer
---@field hsKills number weighted headshot % n
---@field sums table<string, number> stat x rounds
---@field rounds table<string, number> rounds counted
---@field awpCarryKills integer AWP kills if existing
---@field awpCarryDeaths integer? deaths while carrying an AWP if existing

---@return CounterstrikeRecentPlayerStatsData
local function newPlayer()
	return {
		pageName = '', displayName = '', maps = 0, kills = 0, deaths = 0, assists = 0,
		firstKills = 0, firstDeaths = 0, tradeKills = 0, tradeDeaths = 0, hsKills = 0, sums = {}, rounds = {},
		awpCarryKills = 0,
	}
end

---@class CounterstrikeRecentPlayerStats: BaseClass
---@operator call(table): CounterstrikeRecentPlayerStats
---@field args table
---@field limit number
---@field players table<string, CounterstrikeRecentPlayerStatsData>
local RecentPlayerStats = Class.new(function(self, args)
	self.args = args or {}
	self.limit = MathUtil.toInteger(self.args.limit) or 1000
	self.players = {}
end)

---Player key: to ensure space and _ handle same
---and further correct comparison
---@param pageName string
---@return string
local function playerKey(pageName)
	local key = mw.text.trim(pageName):gsub(' ', '_')
	return mw.ustring.upper(mw.ustring.sub(key, 1, 1)) .. mw.ustring.sub(key, 2)
end

---Reads the matchpage records
---@return AbstractConditionNode
function RecentPlayerStats:buildConditions()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('namespace'), Comparator.eq, Namespace.matchNamespaceId()),
	}

	local matchGroupsSpec = TournamentStructure.readMatchGroupsSpec(self.args)
	if not matchGroupsSpec then
		return conditions:add{
			ConditionNode(ColumnName('date'), Comparator.ge, DateExt.getCurrentTimestamp() - MONTH),
		}
	end

	local scope = ConditionTree(BooleanOperator.any)
	Array.forEach(matchGroupsSpec.matchGroupIds, function(matchGroupId)
		scope:add{ConditionNode(ColumnName('match2bracketid'), Comparator.eq, 'MATCH_' .. matchGroupId)}
	end)
	Array.forEach(Array.flatten(matchGroupsSpec.pageNames), function(pageName)
		local _, basePageName = Page.splitPageName(pageName)
		scope:add{ConditionNode(ColumnName('parent'), Comparator.eq, (basePageName:gsub(' ', '_')))}
	end)
	return conditions:add{scope}
end

---Display name, flag and team from the match's roster.
---@param match match2
function RecentPlayerStats:processPlayers(match)
	Array.forEach(match.match2opponents, function(record, opponentIndex)
		local opponent = MatchGroupUtil.opponentFromRecord(match, record, opponentIndex)
		Array.forEach(opponent.players or {}, function(player)
			local data = player.pageName and self.players[playerKey(player.pageName)]
			if data and String.isEmpty(data.pageName) then
				data.pageName = player.pageName
				data.displayName = player.displayName
				data.flag = player.flag
				data.team = opponent.template
			end
		end)
	end)
end

---@param data CounterstrikeRecentPlayerStatsData
---@param player table one map's stats for one player
local function addMap(data, player)
	data.maps = data.maps + 1
	data.kills = data.kills + (player.kills or 0)
	data.deaths = data.deaths + (player.deaths or 0)
	data.assists = data.assists + (player.assists or 0)
	data.firstKills = data.firstKills + (player.firstKills or 0)
	data.firstDeaths = data.firstDeaths + (player.firstDeaths or 0)
	local awpDeathsCarrying = tonumber(player.awpDeathsCarrying)
	if awpDeathsCarrying then
		data.awpCarryKills = data.awpCarryKills + (player.awpKills or 0)
		data.awpCarryDeaths = (data.awpCarryDeaths or 0) + awpDeathsCarrying
	end
	if player.hs and player.kills then
		data.hsKills = data.hsKills + player.hs * player.kills
	end
	data.tradeKills = data.tradeKills + (player.tradeKills or 0)
	data.tradeDeaths = data.tradeDeaths + (player.tradeDeaths or 0)
	Array.forEach(ROUND_WEIGHTED, function(stat)
		local field, weightField = stat[1], stat[2]
		local value = tonumber(player[field])
		if value then
			local weight = tonumber(player[weightField]) or 1
			data.sums[field] = (data.sums[field] or 0) + value * weight
			data.rounds[field] = (data.rounds[field] or 0) + weight
		end
	end)
	local roundsPlayed = tonumber(player.roundsPlayed)
	if roundsPlayed and roundsPlayed > 0 then
		local counts = {
			kills = player.kills,
			entryAttempts = player.firstKills and player.firstDeaths and (player.firstKills + player.firstDeaths) or nil,
			awpKills = player.awpKills,
			msl = player.msl,
		}
		Array.forEach(PER_ROUND_COUNTS, function(field)
			local value = tonumber(counts[field])
			if value then
				data.sums[field] = (data.sums[field] or 0) + value
				data.rounds[field] = (data.rounds[field] or 0) + roundsPlayed
			end
		end)
	end
end

---@param match match2
function RecentPlayerStats:processMatch(match)
	Array.forEach(match.match2games, function(gameRecord)
		local game = MatchGroupUtil.gameFromRecord(gameRecord, #match.match2opponents)
		if game.status == NOT_PLAYED then
			return
		end
		Array.forEach(game.opponents or {}, function(opponent, opponentIndex)
			local teamRecord = match.match2opponents[opponentIndex]
			local team = teamRecord and Logic.nilIfEmpty(teamRecord.template)
			Array.forEach(opponent.players or {}, function(player)
				-- Only players the crosswalk links
				if Logic.isEmpty(player.player) or not player.kills then
					return
				end
				local key = playerKey(player.player)
				local data = self.players[key] or newPlayer()
				if String.isEmpty(data.displayName) then
					data.displayName = player.displayName or player.player
				end
				data.flag = data.flag or player.flag
				-- Latest map wins, failsafe for incorrect team
				data.team = team or data.team
				addMap(data, player)
				self.players[key] = data
			end)
		end)
	end)
end

---@return self
function RecentPlayerStats:query()
	Lpdb.executeMassQuery('match2', {
		conditions = tostring(self:buildConditions()),
		query = 'match2games, match2opponents, bestof',
	}, function(match)
		self:processMatch(match)
		self:processPlayers(match)
	end, self.limit)
	return self
end

---@param data CounterstrikeRecentPlayerStatsData
---@param stat string
---@return number?
local function perRound(data, stat)
	local rounds = data.rounds[stat]
	if not rounds or rounds == 0 then
		return nil
	end
	return data.sums[stat] / rounds
end

---@param value number?
---@param precision integer
---@param suffix string?
---@param signed boolean?
---@return string
local function format(value, precision, suffix, signed)
	if not value then
		return '-'
	end
	local text = MathUtil.formatRounded{value = value, precision = precision} .. (suffix or '')
	return (signed and value > 0) and ('+' .. text) or text
end

---@class CounterstrikeRecentPlayerStatsColumn
---@field header string
---@field title string? hover text on the header
---@field value fun(data: CounterstrikeRecentPlayerStatsData): number?
---@field show fun(value: number?, data: CounterstrikeRecentPlayerStatsData): string
---@field requires string?

---@type CounterstrikeRecentPlayerStatsColumn[]
local STAT_COLUMNS = {
	{header = 'Rating', title = 'L-rating, weighted by rounds',
		value = function(d) return perRound(d, 'rating') end, show = function(v) return format(v, 2) end},
	{header = 'T', title = 'L-rating on the T side',
		value = function(d) return perRound(d, 'ratingT') end, show = function(v) return format(v, 2) end},
	{header = 'CT', title = 'L-rating on the CT side',
		value = function(d) return perRound(d, 'ratingCt') end, show = function(v) return format(v, 2) end},
	{header = 'MSL/24', title = 'Meltdown/shutdown line per 24 rounds',
		value = function(d) local v = perRound(d, 'msl') return v and v * 24 end,
		show = function(v) return format(v, 2, nil, true) end},
	{header = 'K', value = function(d) return d.kills end, show = tostring},
	{header = 'D', value = function(d) return d.deaths end, show = tostring},
	{header = 'A', value = function(d) return d.assists end, show = tostring},
	{header = 'K/D', value = function(d) return d.deaths > 0 and d.kills / d.deaths or nil end,
		show = function(v) return format(v, 2) end},
	{header = 'KPR', title = 'Kills per round',
		value = function(d) return perRound(d, 'kills') end, show = function(v) return format(v, 2) end},
	{header = 'ADR', value = function(d) return perRound(d, 'adr') end, show = function(v) return format(v, 1) end},
	{header = 'KAST', value = function(d) return perRound(d, 'kast') end, show = function(v) return format(v, 1, '%') end},
	{header = 'HS%', value = function(d) return d.kills > 0 and d.hsKills / d.kills or nil end,
		show = function(v) return format(v, 1, '%') end},
	{header = 'Opening', title = 'Opening duels won: first kills / first attempts',
		value = function(d)
			local duels = d.firstKills + d.firstDeaths
			return duels > 0 and 100 * d.firstKills / duels or nil
		end,
		show = function(v) return format(v, 1, '%') end},
	{header = 'EA/Rd', title = 'Entry attempts per round',
		value = function(d) return perRound(d, 'entryAttempts') end, show = function(v) return format(v, 2) end},
	{header = 'TK / TD', title = 'Trade kills / trade death',
		-- Sorted by the difference; shown as both counts.
		value = function(d) return d.tradeKills - d.tradeDeaths end,
		show = function(_, d) return d.tradeKills .. ' / ' .. d.tradeDeaths end},
	{header = 'AWP K/Rd', title = 'AWP kills per round',
		value = function(d) return perRound(d, 'awpKills') end, show = function(v) return format(v, 2) end},
	{header = 'AWP K/D', title = 'AWP kills / deaths',
		requires = 'awpCarry',
		value = function(d)
			if not d.awpCarryDeaths then
				return nil
			end
			return d.awpCarryKills / math.max(d.awpCarryDeaths, 1)
		end,
		show = function(v) return format(v, 2) end},
	{header = 'Alt Swing', title = 'Alternative swing',
		value = function(d) return perRound(d, 'altSwing') end, show = function(v) return format(v, 2, '%', true) end},
	{header = 'Leverage', title = 'Leverage swing',
		value = function(d) return perRound(d, 'leverage') end, show = function(v) return format(v, 2, '%', true) end},
	{header = 'Eco KPR', title = 'Kills per round, adjusted for economy',
		value = function(d) return perRound(d, 'ecoKpr') end, show = function(v) return format(v, 2) end},
	{header = 'Eco DPR', title = 'Deaths per round, adjusted for economy',
		value = function(d) return perRound(d, 'ecoDpr') end, show = function(v) return format(v, 2) end},
	{header = 'Eco ADR', title = 'Damage per round, adjusted for economy',
		value = function(d) return perRound(d, 'ecoAdr') end, show = function(v) return format(v, 1) end},
}

---@return table<string, boolean>
function RecentPlayerStats:availableData()
	return {
		awpCarry = Array.any(Array.extractValues(self.players), function(data)
			return data.awpCarryDeaths ~= nil
		end),
	}
end

---@return CounterstrikeRecentPlayerStatsColumn[]
function RecentPlayerStats:statColumns()
	local available = self:availableData()
	return Array.filter(STAT_COLUMNS, function(column)
		return not column.requires or available[column.requires]
	end)
end

---@protected
---@param statColumns CounterstrikeRecentPlayerStatsColumn[]
---@return Table2ColumnDef[]
function RecentPlayerStats.buildColumnDefinitions(statColumns)
	return WidgetUtil.collect(
		{align = 'left', unsortable = true},
		{align = 'left'},
		{align = 'center'},
		{align = 'center', sortType = 'number'},
		{align = 'center', sortType = 'number'},
		Array.rep({align = 'right', sortType = 'number'}, #statColumns)
	)
end

---@param statColumns CounterstrikeRecentPlayerStatsColumn[]
---@return Widget
function RecentPlayerStats.headerRow(statColumns)
	local function headerCell(text, title)
		return TableWidgets.CellHeader{
			attributes = title and {title = title} or nil,
			children = text,
		}
	end
	return TableWidgets.TableHeader{
		children = TableWidgets.Row{children = WidgetUtil.collect(
			headerCell('#'),
			headerCell('Player'),
			headerCell('Team'),
			headerCell('Maps'),
			headerCell('FK/FD', 'First kills / first deaths'),
			Array.map(statColumns, function(column)
				return headerCell(column.header, column.title)
			end)
		)},
	}
end

---@return string[]
function RecentPlayerStats:getSortedPlayers()
	local keys = Array.extractKeys(self.players)
	local min = MathUtil.toInteger(self.args.minmaps) or 1
	local max = MathUtil.toInteger(self.args.maxmaps) or math.huge
	keys = Array.filter(keys, function(key)
		local maps = self.players[key].maps
		return maps >= min and maps <= max
	end)
	-- Best rating first, players without one at the bottom
	table.sort(keys, function(a, b)
		local ra = perRound(self.players[a], 'rating') or -math.huge
		local rb = perRound(self.players[b], 'rating') or -math.huge
		if ra ~= rb then
			return ra > rb
		end
		return a < b
	end)
	return keys
end

---@param key string
---@param index integer
---@param statColumns CounterstrikeRecentPlayerStatsColumn[]
---@return Widget
function RecentPlayerStats:playerRow(key, index, statColumns)
	local data = self.players[key]
	local player = {
		pageName = Logic.emptyOr(data.pageName, key),
		displayName = Logic.emptyOr(data.displayName, key),
		flag = data.flag,
	}
	local teamRaw = data.team and TeamTemplate.getRawOrNil(data.team) or {}

	return TableWidgets.Row{children = WidgetUtil.collect(
		TableWidgets.Cell{children = index},
		TableWidgets.Cell{
			attributes = {['data-sort-value'] = player.displayName},
			children = PlayerDisplay.BlockPlayer{player = player, showPlayerTeam = false},
			css = {['text-align'] = 'left'},
		},
		TableWidgets.Cell{
			attributes = {['data-sort-value'] = teamRaw.name},
			children = Logic.isNotEmpty(data.team)
				and OpponentDisplay.InlineTeamContainer{template = data.team, style = 'icon'} or nil,
		},
		TableWidgets.Cell{children = data.maps},
		TableWidgets.Cell{
			attributes = {['data-sort-value'] = data.firstKills - data.firstDeaths},
			children = data.firstKills .. ' / ' .. data.firstDeaths,
		},
		Array.map(statColumns, function(column)
			local value = column.value(data)
			return TableWidgets.Cell{
				attributes = {['data-sort-value'] = value or ''},
				children = column.show(value, data),
			}
		end)
	)}
end

---@return Widget
function RecentPlayerStats:build()
	local statColumns = self:statColumns()
	return TableWidgets.Table{
		sortable = true,
		tableCss = {['margin-top'] = '10px', ['text-align'] = 'center'},
		columns = RecentPlayerStats.buildColumnDefinitions(statColumns),
		children = {
			RecentPlayerStats.headerRow(statColumns),
			TableWidgets.TableBody{children = WidgetUtil.collect(
				Table.isEmpty(self.players) and TableWidgets.Row{children = TableWidgets.Cell{
					colspan = 100,
					css = {['font-style'] = 'italic'},
					children = 'There are no stats yet.',
				}} or nil,
				Array.map(self:getSortedPlayers(), function(key, index)
					return self:playerRow(key, index, statColumns)
				end)
			)},
		},
	}
end

---@param frame Frame
---@return Widget
function RecentPlayerStats.get(frame)
	return RecentPlayerStats(Arguments.getArgs(frame)):query():build()
end

return RecentPlayerStats
