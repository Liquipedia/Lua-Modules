---
-- @Liquipedia
-- page=Module:Widget/Basic/Box
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')

---@class BoxProps
---@field children Renderable[]|Renderable
---@field maxWidth string?
---@field paddingLeft string?
---@field paddingBottom string?
---@field paddingRight string?
---@field width string?
---@field height string?

---@class Box: Widget
---@operator call(BoxProps): Box
---@field props BoxProps
local Box = Class.new(Widget)

---@return Widget|Renderable
function Box:render()
	local children = self.props.children
	if not Array.isArray(children) then
		return self.props.children
	end
	---@cast children -Renderable

	return HtmlWidgets.Div{
		css = {['max-width'] = self.props.maxWidth},
		children = Array.map(children, function(child)
			return HtmlWidgets.Div{
				classes = {'template-box'},
				css = {
					['padding-left'] = self.props.paddingLeft,
					['padding-bottom'] = self.props.paddingBottom,
					['padding-right'] = self.props.paddingright,
					width = self.props.width,
					height = self.props.height,
					overflow = self.props.height and 'hidden' or nil,
				},
				children = child,
			}
		end)
	}
end

return Box
