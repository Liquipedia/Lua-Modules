---
-- @Liquipedia
-- page=Module:SeriesMedalStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Medals = require('Module:Medals')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local TODAY = os.date('%Y-%m-%d') --[[@as string]]
---@alias THIRD '3'
local THIRD = '3'
---@alias FOURTH '4'
local FOURTH = '4'
---@alias SEMIFINALIST '3-4'
local SEMIFINALIST = '3-4'

---@class SeriesMedalStatsConfig
---@field series string[]
---@field tier string[]
---@field tierType string[]
---@field cutAfter number
---@field startDate string?
---@field endDate string?
---@field placements string[]
---@field external boolean
---@field hasNumber boolean
---@field offset integer? only valid if hasNumber
---@field limit integer? only valid if hasNumber
---@field additionalConditions string
---@field opponentTypes string[]
---@field mergeIntoSemifinalists boolean

---@class SeriesMedalStatsPlacementObject
---@field opponentplayers table
---@field placement string
---@field date string
---@field extradata table
---@field opponentname string
---@field opponenttype OpponentType
---@field opponenttemplate string?

---@class SeriesMedalStatsDataSet
---@field identifier string
---@field ['1'] number
---@field ['2'] number
---@field [THIRD] number?
---@field [SEMIFINALIST] number?
---@field [FOURTH] number?
---@field total number

---@class SeriesMedalStats
---@operator call(table?): SeriesMedalStats
---@field config SeriesMedalStatsConfig
---@field rawData SeriesMedalStatsPlacementObject[]?
---@field args table
---@field data table?
---@field dataAsArray SeriesMedalStatsDataSet[]?
---@field display Html?
local MedalStats = Class.new(function(self, args) self:init(args) end)

---@param args table?
---@return self
function MedalStats:init(args)
	self.args = args or {}
	self.config = self:_getConfig()

	return self
end

---@return SeriesMedalStatsConfig
function MedalStats:_getConfig()
	local args = self.args

	local placements = {'1', '2'}
	if Logic.readBool(args.bronze) then
		table.insert(placements, THIRD)
	end
	if Logic.readBool(args.sf) then
		table.insert(placements, SEMIFINALIST)
	end
	if Logic.readBool(args.copper) then
		table.insert(placements, FOURTH)
	end

	---@param input string?
	---@param sep string?
	---@return string[]
	local splitAndTrimIfExist = function(input, sep)
		if String.isEmpty(input) then return {} end
		---@cast input -nil
		return Array.map(mw.text.split(input, sep or '||'), String.trim)
	end

	local series = splitAndTrimIfExist(args.series or mw.title.getCurrentTitle().prefixedText)

	if not Logic.readBool(args.noredirect) then
		series = Array.map(series, mw.ext.TeamLiquidIntegration.resolve_redirect)
	end

	series = Array.map(series, function(value) return (value:gsub('_', ' ')) end)

	return {
		series = series,
		external = Logic.readBool(args.external),
		tier = splitAndTrimIfExist(args.tier or args.liquipediatier),
		tierType = splitAndTrimIfExist(args.tiertype or args.liquipediatiertype),
		offset = tonumber(args.offset),
		limit = tonumber(args.limit),
		cutAfter = tonumber(args.cutafter) or 7,
		hasNumber = Logic.isNumeric(args.offset) or Logic.isNumeric(args.limit) or not Logic.readBool(args.noNumber),
		endDate = args.edate,
		startDate = args.sdate,
		placements = placements,
		additionalConditions = args.additionalConditions or '',
		opponentTypes = splitAndTrimIfExist(args.opponentType),
		mergeIntoSemifinalists = Logic.readBool(args.mergeIntoSemifinalists),
	}
end

---@return self
function MedalStats:query()
	self.rawData = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = self:_getConditions(),
		query = 'opponentplayers, placement, extradata, date, opponentname, opponenttype, opponenttemplate',
		sort = 'date desc',
		limit = 5000,
	})

	return self
end

---@return string
function MedalStats:_getConditions()
	local config = self.config
	local conditions = ConditionTree(BooleanOperator.all)

	---@param field string
	---@param arr string[]
	local addOrCondition = function(field, arr)
		if Table.isEmpty(arr) then return end
		conditions:add(ConditionTree(BooleanOperator.any):add(Array.map(arr, function(value)
			return ConditionNode(ColumnName(field), Comparator.eq, value)
		end)))
	end

	addOrCondition('series', config.series)
	addOrCondition('liquipediatier', config.tier)
	addOrCondition('liquipediatiertype', config.tierType)
	addOrCondition('placement', config.placements)
	addOrCondition('opponenttype', config.opponentTypes)

	conditions:add{ConditionNode(ColumnName('date'), Comparator.lt, (config.endDate or TODAY) .. 'T23:59:59')}

	if not config.external then
		conditions:add{ConditionNode(ColumnName('prizepoolindex'), Comparator.eq, 1)}
	end

	if config.hasNumber then
		conditions:add{ConditionNode(ColumnName('extradata_seriesnumber'), Comparator.eq, '!')}
	end

	if config.startDate then
		addOrCondition('date', {config.startDate, '>' .. config.startDate})
	end

	return conditions:toString() .. config.additionalConditions
end

---@return Html?
function MedalStats:create()
	error('The `:create()` function has to be part of part of the specific module')
end

---@return table<string, integer>
function MedalStats:setUpPlacementData()
	return Table.merge(Table.map(self.config.placements, function(key, placement)
		return placement, 0
	end), {total = 0})
end

---@param getIdentifier fun(placement: SeriesMedalStatsPlacementObject): string?
---@param placement SeriesMedalStatsPlacementObject
function MedalStats:processByIdentifier(getIdentifier, placement)
	local identifier = getIdentifier(placement)
	if String.isEmpty(identifier) then return end
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

	self.data[identifier] = self.data[identifier] or self:setUpPlacementData()
	self.data[identifier][placementValue] = self.data[identifier][placementValue] + 1
	self.data[identifier].total = self.data[identifier].total + 1
end

function MedalStats:sort()
	Table.iter.forEachPair(self.data, function(identifier, data)
		data.identifier = identifier
	end)
	self.dataAsArray = Array.extractValues(self.data)
	self.data = nil
	table.sort(self.dataAsArray, MedalStats.compare)
end

---@param row1 SeriesMedalStatsDataSet
---@param row2 SeriesMedalStatsDataSet
---@return boolean
function MedalStats.compare(row1, row2)
	local isNotEqual = function(key)
		return (row1[key] or 0) ~= (row2[key] or 0)
	end
	local compare = function(key)
		return (row1[key] or 0) > (row2[key] or 0)
	end

	if isNotEqual('1') then return compare('1') end
	if isNotEqual('2') then return compare('2') end
	if isNotEqual(THIRD) then return compare(THIRD) end
	if isNotEqual(SEMIFINALIST) then return compare(SEMIFINALIST) end
	if isNotEqual(FOURTH) then return compare(FOURTH) end

	return row1.identifier:lower() < row2.identifier:lower()
end

---@param nameDisplay fun(identifier: string):string|Html
---@param title string
---@param cutAfterPartial string
---@return Html?
function MedalStats:defaultBuild(nameDisplay, title, cutAfterPartial)
	if Table.isEmpty(self.dataAsArray) then
		return
	end
	local display = mw.html.create('table')
		:addClass('wikitable wikitable-striped wikitable-bordered prizepooltable collapsed')
		:css('text-align', 'center')
		:attr('data-cutafter', self.config.cutAfter)
		:attr('data-opentext', 'Show remaining ' .. cutAfterPartial)
		:attr('data-closetext', 'Hide remaining ' .. cutAfterPartial)
		:node(self:header(title))

	Array.forEach(self.dataAsArray, function(dataSet)
		display:node(self:row(dataSet, nameDisplay))
	end)

	return display
end

---@param title string
---@return Html
function MedalStats:header(title)
	local header = mw.html.create('tr')
		:tag('th'):wikitext(title):done()

	for _, place in ipairs(self.config.placements) do
		header:tag('th'):node(Medals.display{medal = place})
	end

	header:tag('th'):css('text-weight', 'bold'):wikitext('Total')

	return header
end

---@param dataSet SeriesMedalStatsDataSet
---@param nameDisplay fun(identifier: string):string|Html
---@return Html
function MedalStats:row(dataSet, nameDisplay)
	local row = mw.html.create('tr')
		:tag('td')
			:css('text-align', 'left')
			:node(nameDisplay(dataSet.identifier))
			:done()

	for _, place in ipairs(self.config.placements) do
		row:tag('td'):wikitext(dataSet[place])
	end

	row:tag('td'):css('font-weight', 'bold'):wikitext(dataSet.total)

	return row
end

return MedalStats
