---
-- @Liquipedia
-- page=Module:Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Patch = {}

---@class StandardPatch
---@field displayName string
---@field pageName string
---@field releaseDate {year: integer, month: integer, day: integer, timestamp: integer, string: string}
---@field version string?
---@field highlights string[]

local function datapointType()
	if Info.wikiName == 'dota2' then
		return 'version'
	end
	return 'patch'
end

---@param date string
---@return StandardPatch?
function Patch.getPatchByDate(date)
	local record = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::' .. datapointType() .. ']] AND ([[date::<' .. date .. ']] OR [[date::' .. date .. ']])',
		order = 'date desc',
		limit = 1,
	})[1]
	if not record then
		return nil
	end
	return Patch.patchFromRecord(record)
end

---@param config {game: string?, startDate: integer?, endDate: integer?, year: integer?, limit: string|integer?}
---@return StandardPatch[]
function Patch.getByGameYearStartDateEndDate(config)
	local conditions = ConditionTree(BooleanOperator.all):add(Array.append(
		{ConditionNode(ColumnName('type'), Comparator.eq, 'patch')},
		config.game and ConditionNode(ColumnName('extradata_game'), Comparator.eq, config.game) or nil,
		config.year and ConditionNode(ColumnName('date_year'), Comparator.eq, config.year) or nil,
		config.startDate and ConditionNode(ColumnName('date'), Comparator.ge, config.startDate) or nil,
		config.endDate and ConditionNode(ColumnName('date'), Comparator.le, config.endDate) or nil
	))

	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions:toString(),
		order = 'date desc, pagename desc',
		limit = config.limit or 100,
	})

	return Array.map(records, Patch.patchFromRecord)
end

---@param config {game: string?}
---@return StandardPatch?
function Patch.getLatestPatch(config)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, 'patch'),
		config.game and ConditionNode(ColumnName('extradata_game'), Comparator.eq, config.game) or nil
	}

	local record = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = conditions:toString(),
		order = 'date desc, pagename desc',
		limit = 1,
	})[1]
	if type(record) ~= 'table' then
		return nil
	end

	return Patch.patchFromRecord(record)
end

---@param record datapoint
---@return StandardPatch
function Patch.patchFromRecord(record)
	local releaseDate = DateExt.parseIsoDate(record.date) --[[@as table so we can push stuff into it]]
	releaseDate.timestamp = DateExt.readTimestamp(record.date)
	releaseDate.string = record.date

	local patch = {
		displayName = record.name,
		pageName = record.pagename,
		releaseDate = releaseDate,
		version = record.information or (record.extradata or {}).version,
		highlights = record.extradata.highlights or {},
	}

	return patch
end

return Patch
