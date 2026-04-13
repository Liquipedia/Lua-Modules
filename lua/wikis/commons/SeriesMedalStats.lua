---
-- @Liquipedia
-- page=Module:SeriesMedalStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local TODAY = os.date('%Y-%m-%d') --[[@as string]]
---@alias THIRD 3
local THIRD = 3
---@alias FOURTH 4
local FOURTH = 4
---@alias SEMIFINALIST '3-4'
local SEMIFINALIST = '3-4'

---@class SeriesMedalStatsConditionConfig
---@field series string[]
---@field tier string[]
---@field tierType string[]
---@field startDate string?
---@field endDate string?
---@field external boolean
---@field additionalConditions string
---@field opponentTypes string[]
---@field hasNumber boolean

---@class SeriesMedalStatsConfig
---@field cutAfter number
---@field columns string[]
---@field mergeIntoSemifinalists boolean
---@field offset integer? only valid on craft wikis
---@field limit integer? only valid on craft wikis

---@class SeriesMedalStatsDataSet
---@field [1] number
---@field [2] number
---@field [THIRD] number?
---@field [SEMIFINALIST] number?
---@field [FOURTH] number?
---@field total number

---@class SeriesMedalStats
---@operator call(table?): SeriesMedalStats
---@field config SeriesMedalStatsConfig
---@field args table
---@field rawData placement[]?
---@field data table<string, SeriesMedalStatsDataSet>?
local MedalStats = Class.new(function(self, args) self:init(args) end)

---@param args table?
---@return self
function MedalStats:init(args)
	self.config = self:_getConfig(args or {})
	self.rawData = self:query(args or {})

	return self
end

---@param args table
---@return SeriesMedalStatsConfig
function MedalStats:_getConfig(args)
	local columns = Array.extend(
		1,
		2,
		Logic.readBool(args.bronze) and THIRD or nil,
		Logic.readBool(args.sf) and SEMIFINALIST or nil,
		Logic.readBool(args.copper) and FOURTH or nil,
		'total'
	)

	return {
		cutAfter = MathUtil.toInteger(args.cutafter) or 7,
		columns = columns,
		mergeIntoSemifinalists = Logic.readBool(args.mergeIntoSemifinalists),
		offset = MathUtil.toInteger(args.offset),
		limit = MathUtil.toInteger(args.limit),
	}
end

---@param args table
---@return placement[]
function MedalStats:query(args)
	return mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = self:_getConditions(args),
		query = 'opponentplayers, placement, extradata, date, opponentname, opponenttype, opponenttemplate',
		order = 'date asc',
		limit = 5000,
	})
end

---@param args table
---@return SeriesMedalStatsConditionConfig
function MedalStats:_getConditionConfig(args)
	local series = Array.parseCommaSeparatedString(args.series or mw.title.getCurrentTitle().prefixedText)
	if not Logic.readBool(args.noredirect) then
		series = Array.map(series, mw.ext.TeamLiquidIntegration.resolve_redirect)
	end
	series = Array.map(series, function(value) return (value:gsub('_', ' ')) end)

	return {
		series = series,
		external = Logic.readBool(args.external),
		tier = Array.parseCommaSeparatedString(args.tier or args.liquipediatier),
		tierType = Array.parseCommaSeparatedString(args.tiertype or args.liquipediatiertype),
		endDate = args.edate,
		startDate = args.sdate,
		additionalConditions = args.additionalConditions or '',
		opponentTypes = Array.parseCommaSeparatedString(args.opponentType),
		hasNumber = Logic.isNumeric(args.offset) or Logic.isNumeric(args.limit) or not Logic.readBool(args.noNumber),
	}
end

---@param args table
---@return string
function MedalStats:_getConditions(args)
	local config = self:_getConditionConfig(args)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.anyOf(ColumnName('placement'), self.config.columns),
		ConditionUtil.anyOf(ColumnName('series'), config.series),
		ConditionUtil.anyOf(ColumnName('liquipediatier'), config.tier),
		ConditionUtil.anyOf(ColumnName('liquipediatiertype'), config.tierType),
		ConditionUtil.anyOf(ColumnName('opponenttype'), config.opponentTypes),
		ConditionNode(ColumnName('date'), Comparator.lt, (config.endDate or TODAY) .. 'T23:59:59'),
		not config.external and ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, 1) or nil,
		config.hasNumber and ConditionNode(ColumnName('extradata_seriesnumber'), Comparator.eq, '!') or nil,
		config.startDate and ConditionNode(ColumnName('date'), Comparator.ge, config.startDate) or nil,
	}

	return tostring(conditions) .. config.additionalConditions
end

---@return Widget?
function MedalStats:create()
	error('The `:create()` function has to be part of part of the specific module')
end

---@return SeriesMedalStatsDataSet
function MedalStats:setUpPlacementData()
	return Table.map(self.config.columns, function(key, col)
		return col, 0
	end)
end

---@param getIdentifier fun(placement: placement): string?
---@param placement placement
function MedalStats:processByIdentifier(getIdentifier, placement)
	local identifier = getIdentifier(placement)
	if Logic.isEmpty(identifier) then return end
	---@cast identifier -nil

	local seriesNumber = tonumber((placement.extradata or {}).seriesnumber) or 0
	local offset = self.config.offset
	local limit = self.config.limit
	if (offset and seriesNumber <= offset) or (limit and seriesNumber > limit) then
		return
	end

	local placementValue = placement.placement
	if self.config.mergeIntoSemifinalists and (placementValue == THIRD or placementValue == FOURTH) then
		placementValue = SEMIFINALIST
	end
	local cleanedPlacementValue = tonumber(placementValue) or placementValue

	self.data[identifier] = self.data[identifier] or self:setUpPlacementData()
	self.data[identifier][cleanedPlacementValue] = self.data[identifier][cleanedPlacementValue] + 1
	self.data[identifier].total = self.data[identifier].total + 1
end

---@param tbl table<string, SeriesMedalStatsDataSet>
---@param key1 any
---@param key2 any
---@return boolean
function MedalStats.rowSort(tbl, key1, key2)
	---@param key string|integer
	---@return boolean?
	local compare = function(key)
		local val1 = tbl[key1][key] or 0
		local val2 = tbl[key2][key] or 0
		if val1 == val2 then return end
		return val1 > val2
	end

	return Logic.nilOr(
		compare(1),
		compare(2),
		compare(THIRD),
		compare(SEMIFINALIST),
		compare(FOURTH),
		key1:lower() < key2:lower()
	)
end

return MedalStats
