local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Box = require('Module:Box')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local COLUMN_BREAK = 6

---@class TranslationList: Widget
---@operator call(table): TranslationList
local TranslationList = Class.new(Widget)

---@return Widget?
function TranslationList:render()
	---@param item {flag: string, value: string, postFix: string?}
	---@return string
	local displayItem = function(item)
		return Flags.Icon{flag = item.flag} .. (item.postFix or ' ') .. item.value
	end

	---@type Widget[]
	local parts = Array.map(self:_parse(), function(group)
		return UnorderedList{children = Array.map(group, displayItem)}
	end)

	return WidgetUtil.collect(
		Box._template_box_start{padding = '2em'},
		Array.interleave(parts, Box.brk{padding = '2em'}),
		Box.finish()
	)
end

---@return {flag: string, value: string, postFix: string?}[][]
function TranslationList:_parse()
	local data = Array.map(Array.extractKeys(self.props), function(key)
		if key == 'children' then
			return
		elseif key == 'simpliefiedChinese' or key == 'chineseSimplified' then
			return {flag = 'cn', value = self.props[key], postFix = ' (simplified) '}
		elseif key == 'traditionalChinese' or key == 'chineseTraditional' then
			return {flag = 'cn', value = self.props[key], postFix = ' (traditional) '}
		end
		return {
			flag = assert(Logic.nilIfEmpty(Flags.CountryCode{flag = key}), 'Unsupported parameter: ' .. key),
			value = self.props[key],
		}
	end)

	Array.sortInPlaceBy(data, Operator.property('flag'))

	local groupedData = {}
	Array.forEach(data, function(item, index)
		if index % COLUMN_BREAK == 1 then
			table.insert(groupedData, {})
		end
		table.insert(groupedData[#groupedData], item)
	end)

	return groupedData
end

return TranslationList
