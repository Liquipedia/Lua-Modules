---
-- @Liquipedia
-- page=Module:Widget/Basic/Label
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class GenericLabelProps
---@field css table<string, string|number>?
---@field children Renderable|Renderable[]
---@field labelScheme string?
---@field labelType string?

---@class GenericLabel: Widget
---@operator call(GenericLabelProps): GenericLabel
---@field props GenericLabelProps
local GenericLabel = Class.new(Widget)

---@return Widget
function GenericLabel:render()
	local props = self.props
	return HtmlWidgets.Div{
		attributes = props.labelType and {
			['data-label-type'] = props.labelType
		} or nil,
		classes = {
			'generic-label',
			props.labelScheme and ('label--' .. props.labelScheme) or nil,
		},
		css = props.css,
		children = props.children,
	}
end

return GenericLabel
