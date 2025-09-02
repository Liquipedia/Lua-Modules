---
-- @Liquipedia
-- page=Module:WarningBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local WarningBox = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WarningBoxWidget = Lua.import('Module:Widget/WarningBox')

---@param text string|number
---@return Widget
function WarningBox.display(text)
	return WarningBoxWidget{text = text}
end

---@param arr (string|number)[]
---@return Widget
function WarningBox.displayAll(arr)
	return HtmlWidgets.Fragment{
		children = Array.map(arr, WarningBox.display)
	}
end

return WarningBox
