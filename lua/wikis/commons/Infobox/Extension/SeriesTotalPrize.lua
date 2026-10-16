---
-- @Liquipedia
-- page=Module:Infobox/Extension/SeriesTotalPrize
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local SeriesTotalPrize = {}

---@param frame Frame
---@return string
function SeriesTotalPrize.run(frame)
	local args = Arguments.getArgs(frame)

	local series = Array.parseCommaSeparatedString(args.series or mw.title.getCurrentTitle().prefixedText, '||')
	series = Array.map(series, Page.pageifyLink)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.anyOf(ColumnName('seriespage'), series),
		ConditionNode(ColumnName('prizepool'), Comparator.gt, 0),
		ConditionUtil.anyOf(ColumnName('status'), {'finished', ''}),
	}

	local parseToFormattedNumber = function(input)
		local int = MathUtil.toInteger(input)
		if not int then return end
		return string.format("%05d", int)
	end

	local offset = parseToFormattedNumber(args.offset)
	if offset then
		conditions:add(ConditionNode(ColumnName('extradata_seriesnumber'), Comparator.gt, offset))
	end
	local limit = parseToFormattedNumber(args.limit)
	if limit then
		conditions:add(ConditionNode(ColumnName('extradata_seriesnumber'), Comparator.le, limit))
	end

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = tostring(conditions),
		query = 'prizepool, liquipediatier',
		limit = 5000,
	})

	if not data[1] then
		return '$0'
	end

	local sums = {total = 0}
	Array.forEach(data, function(item)
		local value = (tonumber(item.prizepool) or 0)
		sums[item.liquipediatier] = (sums[item.liquipediatier] or 0) + value
		sums.total = sums.total + value
	end)

	---@param value number
	---@param tier string|integer?
	---@return string
	local displayRow = function(value, tier)
		local row = '≃ ' .. Currency.display('USD', value, {formatPrecision = 0, formatValue = true})
		if not tier then
			return row
		end
		return Tier.display(tier) .. ': ' .. row
	end

	local rows = {
		displayRow(Table.extract(sums, 'total'))
	}

	if Logic.readBool(args.onlytotal) or Table.size(sums) == 1 then
		return rows[1]
	end

	for tier, value in Table.iter.spairs(sums) do
		table.insert(rows, displayRow(value, tier))
	end

	return table.concat(Array.interleave(rows, '<br>'))
end

return SeriesTotalPrize
