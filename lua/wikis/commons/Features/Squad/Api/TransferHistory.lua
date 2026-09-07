---
-- @Liquipedia
-- page=Module:Features/Squad/Api/TransferHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Condition = Lua.import('Module:Condition')
local Json = Lua.import('Module:Json')
local Lpdb = Lua.import('Module:Lpdb')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local SquadHistory = Lua.import('Module:Features/Squad/Lib/History')

local BooleanOperator = Condition.BooleanOperator
local Comparator = Condition.Comparator

local pageVars = PageVariableNamespace()

local QUERY_LIMIT = 5000
local QUERY_ORDER = 'date asc, objectname desc'

--- Every transfer read the squad tables do.
local SquadTransferHistory = {}

---Builds the conditions to fetch all transfers related
---to the given team, respecting historical templates.
---@private
---@param teams string[]
---@return string
function SquadTransferHistory._buildConditions(teams)
	local conditions = Condition.Tree(BooleanOperator.any)
	Array.forEach(teams, function (templatename)
		conditions:add{
			Condition.Node(Condition.ColumnName('fromteamtemplate'), Comparator.eq, templatename),
			Condition.Node(Condition.ColumnName('extradata_fromteamsectemplate'), Comparator.eq, templatename),
			Condition.Node(Condition.ColumnName('toteamtemplate'), Comparator.eq, templatename),
			Condition.Node(Condition.ColumnName('extradata_toteamsectemplate'), Comparator.eq, templatename)
		}
	end)

	return conditions:toString()
end

---Reads the team history of everyone who ever joined or left the given team.
---The result is cached in a page variable, so several squad tables on one page share one query.
---@param team string the team the squad table is for, used as the cache key
---@param teams string[] every team template that counts as that team
---@return table<string, TeamHistoryEntry[]>
function SquadTransferHistory.forTeam(team, teams)
	local teamHistoryKey = team .. '_all_transfers'

	---@type table<string, TeamHistoryEntry[]>?
	local cached = Json.parseIfTable(pageVars:get(teamHistoryKey))
	if cached then
		return cached
	end

	local records = {}
	Lpdb.executeMassQuery(
		'transfer',
		{
			conditions = SquadTransferHistory._buildConditions(teams),
			order = QUERY_ORDER,
			limit = QUERY_LIMIT
		},
		function(record)
			table.insert(records, record)
		end
	)

	local playersTeamHistory = SquadHistory.fromTransfers(records, teams)
	pageVars:set(teamHistoryKey, Json.stringify(playersTeamHistory))

	return playersTeamHistory
end

---Fetches the next team a person joined after a given date
---@param pagename string
---@param date string
---@return string? newTeam
---@return string? newRole
---@return string? newDate
function SquadTransferHistory.fetchNextTeam(pagename, date)
	local conditions = Condition.Tree(BooleanOperator.all)
		:add{
			Condition.Util.anyOf(Condition.ColumnName('player'), {pagename, (string.gsub(pagename, ' ', '_'))}),
			Condition.Node(Condition.ColumnName('date'), Comparator.ge, date),
			Condition.Node(Condition.ColumnName('toteamtemplate'), Comparator.neq, ''),
		}

	local transfer = mw.ext.LiquipediaDB.lpdb('transfer', {
		conditions = conditions:toString(),
		limit = 1,
		order = QUERY_ORDER,
		query = 'toteamtemplate, role2, date'
	})[1] or {}

	return transfer.toteamtemplate, transfer.role2, transfer.date
end

return SquadTransferHistory
