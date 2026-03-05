---
-- @Liquipedia
-- page=Module:Map
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Map = {}

---@class StandardMap
---@field displayName string
---@field pageName string
---@field releaseDate {year: integer, month: integer, day: integer, timestamp: integer, string: string}
---@field image string?
---@field creators string[]
---@field game string?
---@field gameModes string[]?
---@field extradata table

---@param props {
---additionalConditions: AbstractConditionNode|AbstractConditionNode[]?,
---limit: string|integer?,
---order: string?,
---}?
---@return StandardMap[]
function Map.queryMaps(props)
	props = props or {}
	local conditions = ConditionTree(BooleanOperator.all)
		:add(ConditionNode(ColumnName('type'), Comparator.eq, 'map'))
	if props.additionalConditions then
		conditions:add(props.additionalConditions)
	end
	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(conditions),
		order = props.order,
		limit = tonumber(props.limit) or 100,
	})

	return Array.map(records, Map.fromRecord)
end

---@param name string
---@return StandardMap?
function Map.getMapByName(name)
	if Logic.isEmpty(name) then return end
	---@cast name -nil

	return Map.queryMaps{
		additionalConditions = ConditionNode(ColumnName('name'), Comparator.eq, name),
		limit = 1,
		order = 'date desc'
	}[1]
end

---@param pageName string?
---@return StandardMap?
function Map.getMapByPageName(pageName)
	if Logic.isEmpty(pageName) then return end
	---@cast pageName -nil

	return Map.queryMaps{
		additionalConditions = ConditionNode(ColumnName('pagename'), Comparator.eq, pageName:gsub(' ', '_')),
		limit = 1,
		order = 'date desc'
	}[1]
end

---@param config {game: string?}
---@return StandardMap?
function Map.getNewestMap(config)
	return Map.queryMaps{
		additionalConditions = config.game and ConditionNode(ColumnName('game'), Comparator.eq, config.game) or nil,
		order = 'date desc, pagename desc',
		limit = 1
	}[1]
end

---@param record datapoint
---@return StandardMap
function Map.fromRecord(record)
	local releaseDate = DateExt.parseIsoDate(record.date) --[[@as table so we can push stuff into it]]
	releaseDate.timestamp = DateExt.readTimestamp(record.date)
	releaseDate.string = record.date

	---@type string[]
	local creators = {}

	for _, creator in Table.iter.pairsByPrefix(record.extradata, 'creator', {requireIndex = false}) do
		table.insert(creators, creator)
	end

	---@type StandardMap
	local map = {
		displayName = record.name,
		pageName = record.pagename,
		releaseDate = releaseDate,
		image = record.image,
		creators = creators,
		game = Table.extract(record.extradata, 'game'),
		gameModes = Table.extract(record.extradata, 'modes'),
		extradata = record.extradata
	}

	return map
end

return Map
