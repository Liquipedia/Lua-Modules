---
-- @Liquipedia
-- page=Module:WarningBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local WarningBox = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@param text string|number
---@return Widget
function WarningBox.display(text)
	local tbl = HtmlWidgets.Table{
		children = HtmlWidgets.Tr{
			children = {
				HtmlWidgets.Td{
					classes = {'ambox-image'},
					children = IconImage{imageLight = 'Emblem-important.svg', size = '40px', link = ''}
				},
				HtmlWidgets.Td{
					classes = {'ambox-text'},
					children = text
				},
			}
		}
	}

	return HtmlWidgets.Div{
		classes = {
			'show-when-logged-in',
			'navigation-not-searchable',
			'ambox-wrapper',
			'ambox',
			'wiki-bordercolor-dark',
			'wiki-backgroundcolor-light',
			'ambox-red'
		},
		children = tbl
	}
end

---@param arr (string|number)[]
---@return Widget
function WarningBox.displayAll(arr)
	return HtmlWidgets.Fragment{
		children = Array.map(arr, WarningBox.display)
	}
end

return WarningBox
