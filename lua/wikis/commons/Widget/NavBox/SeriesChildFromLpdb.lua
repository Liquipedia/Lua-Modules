---
-- @Liquipedia
-- page=Module:Widget/NavBox/SeriesChildFromLpdb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Widget = Lua.import('Module:Widget')

---- technically from wiki input they will be all string representations
---@class SeriesChildFromLpdbProps: NavBoxChildProps
---@field limit integer?
---@field offset integer?
---@field newestFirst boolean?
---@field prependManualChildren boolean?
---@field series string[]|string
---@field resolve boolean?
---@field tier string?
---@field tierType string?
---@field mode string?
---@field year integer
---@field edate string|integer|osdate?
---@field sdate string|integer|osdate?

---@class SeriesChildFromLpdb: Widget
---@field props SeriesChildFromLpdbProps
local SeriesChildFromLpdb = Class.new(Widget)
SeriesChildFromLpdb.defaultProps = {
	newestFirst = true,
	resolve = true,
}

---@return string
function SeriesChildFromLpdb:render()
	local props = self.props

	local limit = tonumber(props.limit)
	local offset = tonumber(props.offset)

	---@param tournament StandardTournament
	---@return integer|string
	local getSeriesNumber = function(tournament)
		return tonumber((tournament.extradata or {}).seriesnumber)
			or tonumber((tournament.pageName:gsub('.*/([%d%.]+)$', '%1')))
			or 'invalid number'
	end

	---@param tournament StandardTournament
	---@return boolean
	local filterbyLimitAndOffSet = function(tournament)
		if not limit and not offset then return true end
		local seriesNumber = tonumber(getSeriesNumber(tournament))
		if not seriesNumber then
			return false
		elseif limit and seriesNumber > limit then
			return false
		elseif offset and seriesNumber <= offset then
			return false
		end
		return true
	end

	local tournaments = Tournament.getAllTournaments(self:_makeConditions(), filterbyLimitAndOffSet)

	local elements = Array.map(tournaments, function(tournament)
		-- can not use `Link` Widget due to `Json.stringify` below
		return Page.makeInternalLink('#' .. getSeriesNumber(tournament), tournament.pageName)
	end)

	if Logic.readBool(props.newestFirst) then
		elements = Array.reverse(elements)
	end

	local manualElements = Array.mapIndexes(function(index) return props[index] end)
	if Logic.readBool(props.prependManualChildren) then
		elements = Array.extend(manualElements, elements)
	else
		Array.extendWith(elements, manualElements)
	end

	return Json.stringify(Table.merge(props, elements))
end

---@private
---@return ConditionTree
function SeriesChildFromLpdb:_makeConditions()
	local props = self.props

	---@type string[]
	local serieses = Json.parseIfTable(props.series)
		or Array.isArray(props.series) and props.series --[[@as string[] ]]
		or {props.series}

	assert(Logic.isNotEmpty(serieses), 'No series specified')

	local prepPageName = Logic.nilOr(Logic.readBoolOrNil(props.resolve), true) and Page.pageifyLink or function(pageName)
		return (pageName:gsub(' ', '_'))
	end

	serieses = Array.map(serieses, prepPageName)

	---@param key string
	---@param items string[]
	---@return ConditionTree?
	local multiValueCondition = function(key, items)
		if Logic.isEmpty(items) then return end

		return ConditionTree(BooleanOperator.any):add(
			Array.map(items, function(item)
				return ConditionNode(ColumnName(key), Comparator.eq, item)
			end)
		)
	end

	local year = tonumber(props.year)

	return ConditionTree(BooleanOperator.all):add{
		multiValueCondition('seriespage', serieses),
		multiValueCondition('liquipediatier', Json.parseIfTable(props.tier) or {props.tier}),
		multiValueCondition('liquipediatiertype', Json.parseIfTable(props.tierType) or {props.tierType}),
		multiValueCondition('mode', Json.parseIfTable(props.mode) or {props.mode}),
		year and ConditionNode(ColumnName('enddate_year'), Comparator.eq, year) or nil,
		props.edate and ConditionNode(ColumnName('enddate'), Comparator.le, props.edate) or nil,
		props.sdate and ConditionNode(ColumnName('startdate'), Comparator.ge, props.sdate) or nil,
	}
end

return SeriesChildFromLpdb
