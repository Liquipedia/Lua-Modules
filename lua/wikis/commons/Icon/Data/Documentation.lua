---
-- @Liquipedia
-- page=Module:Icon/Data/Documentation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local IconData = Lua.import('Module:Icon/Data', {loadData = true})
local Table = Lua.import('Module:Table')

local Html = Lua.import('Module:Widget/Html')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local ListWidgets = Lua.import('Module:Widget/List')

local IconDataDoc = {}

---@return Widget
function IconDataDoc.generate()
	local iconNames = Array.extractKeys(IconData)
	local _, groupedIconNames = Array.groupBy(iconNames, function(iconName)
		return iconName:sub(1,1):upper()
	end)

	local children = {}
	for letter, group in Table.iter.spairs(groupedIconNames) do
		Array.sortInPlaceBy(group, FnUtil.identity)

		Array.appendWith(children,
			Html.H3{children = letter},
			ListWidgets.Unordered{children = Array.map(group, IconDataDoc._displayIcon)}
		)
	end

	return Html.Fragment{children = children}
end

---@param iconName string
---@return Renderable[]
function IconDataDoc._displayIcon(iconName)
	return {
		iconName,
		': ',
		Icon{iconName = iconName, size = '1rem'},
	}
end

return IconDataDoc
