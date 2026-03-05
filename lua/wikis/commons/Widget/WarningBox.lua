---
-- @Liquipedia
-- page=Module:Widget/WarningBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class WarningBoxWidget: Widget
---@operator call(table): WarningBoxWidget
---@field props {text: string|number?}
local WarningBoxWidget = Class.new(Widget)

---@return Widget?
function WarningBoxWidget:render()
	local text = self.props.text
	if Logic.isEmpty(text) then
		return
	end
	---@cast text -nil

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

return WarningBoxWidget
