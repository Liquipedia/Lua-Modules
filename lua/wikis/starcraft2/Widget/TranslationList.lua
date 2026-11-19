---
-- @Liquipedia
-- page=Module:Widget/TranslationList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local Box = Lua.import('Module:Widget/Basic/Box')
local Component = Lua.import('Module:Widget/Component')
local ListWidgets = Lua.import('Module:Widget/List')

local COLUMN_BREAK = 6

---@alias TranslationListItem {flag: string, value: string, postFix: string?}

local Helpers = {}

---@param props table<string, string>
---@return VNode
local function TranslationList(props)
	---@param item TranslationListItem
	---@return string
	local displayItem = function(item)
		return Flags.Icon{flag = item.flag} .. (item.postFix or ' ') .. item.value
	end

	---@type VNode[]
	local parts = Array.map(Helpers._parse(props), function(group)
		return ListWidgets.Unordered{children = Array.map(group, displayItem)}
	end)

	return Box{children = parts}
end

---@private
---@param props table<string, string>
---@return TranslationListItem[][]
function Helpers._parse(props)
	local data = Array.map(Array.extractKeys(props), function(key)
		if key == 'children' then
			return
		elseif key == 'simpliefiedChinese' or key == 'chineseSimplified' then
			return {flag = 'cn', value = props[key], postFix = ' (simplified) '}
		elseif key == 'traditionalChinese' or key == 'chineseTraditional' then
			return {flag = 'cn', value = props[key], postFix = ' (traditional) '}
		end
		return {
			flag = assert(Logic.nilIfEmpty(Flags.CountryCode{flag = key}), 'Unsupported parameter: ' .. key),
			value = props[key],
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

return Component.component(TranslationList)
