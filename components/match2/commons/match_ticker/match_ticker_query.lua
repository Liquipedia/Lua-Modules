---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/Query
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local _CURRENT_DATE_STAMP = os.date('%Y-%m-%d %H:%M', os.time(os.date('!*t') --[[@as osdate]]))

local _LIMIT_INCREASE = 20
local _DEFAULT_LIMIT = 20
local _DEFAULT_QUERY_COLUMNS = {
	'match2opponents',
	'winner',
	'pagename',
	'tournament',
	'tickername',
	'icon',
	'date',
	'publishertier',
	'vod',
	'stream',
	'extradata',
	'parent',
	'finished',
	'bestof',
	'match2id',
	'icondark',
}
local _ORDER_DEFAULT = 'date asc, liquipediatier asc, tournament asc'

local MatchTickerQuery = Class.new()
MatchTickerQuery.maximumLiveHoursOfMatches = 3

local Query = Class.new(
	function(self)
		self.queryColumns = _DEFAULT_QUERY_COLUMNS
		self.orderValue = _ORDER_DEFAULT
		self.limitValue = _DEFAULT_LIMIT + _LIMIT_INCREASE
	end
)

function Query:addQueryColumn(queryColumn)
	table.insert(self.queryColumns, queryColumn)
	return self
end

function Query:setOrder(order)
	self.orderValue = order
	return self
end

function Query:setConditions(conditions)
	self.conditions = conditions
	return self
end

function Query:setLimit(limit)
	-- increase the limit in case we have inelligable matches, such as:
	-- > matches with lpdb query bugs that we can not fix (e.g. missing opponent append)
	-- > for player/team pages: recent matches that contain a "TBD" or empty opponent
	-- > for main page mass "TBD"(or empty) vs "TBD"(or empty) from the same page
	-- with the limit increase we query a few more matches so that if inelligable are removed
	-- we still have enough to reach the limt (if the other conditions allow it)
	self.limitValue = limit + _LIMIT_INCREASE
	return self
end

function Query:get()
	local data = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = self.conditions,
		order = self.orderValue,
		query = table.concat(self.queryColumns, ', '),
		limit = self.limitValue
	})

	if type(data[1]) == 'table' then
		return data
	end
end

-- class that builds the base conditions and returns them as a condition tree
local BaseConditions = Class.new(
	function(self)
		self.conditionTree = ConditionTree(BooleanOperator.all)
	end
)

function BaseConditions:addDefaultConditions(queryArgs)
	local tournamentConditions = BaseConditions:tournamentConditions(queryArgs)
	if tournamentConditions then
		self.conditionTree:add(tournamentConditions)
	end

	local participantConditions = BaseConditions:participantConditions(queryArgs)
	if participantConditions then
		self.conditionTree:add(participantConditions)
	end

	local dateConditions = BaseConditions:dateConditions(queryArgs)
	if dateConditions then
		self.conditionTree:add(dateConditions)
	end

	return self
end

function BaseConditions:tournamentConditions(queryArgs)
	local tournaments = {}
	local tournament = queryArgs.tournament or queryArgs.tournament1 or queryArgs[1]
	local tournamentIndex = 1
	while String.isNotEmpty(tournament) do
		tournament = mw.ext.TeamLiquidIntegration.resolve_redirect(tournament)
		tournament = string.gsub(tournament, '%s', '_')
		table.insert(tournaments, tournament)
		tournamentIndex = tournamentIndex + 1
		tournament = queryArgs['tournament' .. tournamentIndex] or queryArgs[tournamentIndex]
	end
	if not Table.isEmpty(tournaments) then
		local tournamentConditionTree = ConditionTree(BooleanOperator.any)
		for _, item in pairs(tournaments) do
			tournamentConditionTree:add({ConditionNode(ColumnName('pagename'), Comparator.eq, item)})
		end
		return tournamentConditionTree
	elseif Logic.readBool(queryArgs.byParent) then
		return ConditionNode(ColumnName('parent'), Comparator.eq,
			queryArgs.parent or Variables.varDefault('tournament_parent'))
	end

	return nil
end

function BaseConditions:participantConditions(queryArgs)
	if String.isNotEmpty(queryArgs.team) then
		return ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponent'), Comparator.eq, queryArgs.team),
			ConditionNode(ColumnName('opponent'), Comparator.eq, queryArgs.team:gsub(' ', '_')),
		}
	elseif String.isNotEmpty(queryArgs.player) then
		return ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('player'), Comparator.eq, queryArgs.player),
			ConditionNode(ColumnName('opponent'), Comparator.eq, queryArgs.player),
			ConditionNode(ColumnName('player'), Comparator.eq, queryArgs.player:gsub(' ', '_')),
			ConditionNode(ColumnName('opponent'), Comparator.eq, queryArgs.player:gsub(' ', '_')),
		}
	end
end

function BaseConditions:dateConditions(queryArgs)
	local dateConditions = ConditionTree(BooleanOperator.all)
	if not Logic.readBool(queryArgs.notExact) then
		dateConditions:add({ConditionNode(ColumnName('dateexact'), Comparator.eq, 1)})
	end
	if Logic.readBool(queryArgs.recent) then
		dateConditions:add({
			ConditionNode(ColumnName('finished'), Comparator.eq, 1),
			ConditionNode(ColumnName('date'), Comparator.lt, _CURRENT_DATE_STAMP),
		})
	else
		dateConditions:add({ConditionNode(ColumnName('finished'), Comparator.eq, 0)})

		if Logic.readBool(queryArgs.ongoing) then
			local secondsLive = 60 * 60 * MatchTickerQuery.maximumLiveHoursOfMatches
			local timeStamp = os.date('%Y-%m-%d %H:%M', os.time(os.date('!*t') --[[@as osdate]]) - secondsLive)
			dateConditions:add({ConditionNode(ColumnName('date'), Comparator.gt, timeStamp)})

			if not Logic.readBool(queryArgs.upcoming) then
				dateConditions:add({ConditionNode(ColumnName('date'), Comparator.lt, _CURRENT_DATE_STAMP)})
			end

		elseif Logic.readBool(queryArgs.upcoming) then
			dateConditions:add({ConditionNode(ColumnName('date'), Comparator.gt, _CURRENT_DATE_STAMP)})
		end
	end

	return dateConditions
end

function BaseConditions:build(queryArgs)
	return self.conditionTree:toString()
end

MatchTickerQuery.Query = Query
MatchTickerQuery.BaseConditions = BaseConditions.export()

return MatchTickerQuery
