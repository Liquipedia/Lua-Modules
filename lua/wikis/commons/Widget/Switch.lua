---
-- @Liquipedia
-- page=Module:Widget/Switch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class SwitchParameters
---@field label string
---@field switchGroup string
---@field storeValue boolean
---@field defaultActive boolean
---@field css table?
---@field content Renderable|Renderable[]?
---@field collapsibleSelector string?

---@class SwitchWidget: Widget
---@operator call(SwitchParameters): SwitchWidget
---@field props SwitchParameters
local SwitchWidget = Class.new(Widget)
SwitchWidget.defaultProps = {
	label = '',
	switchGroup = 'switch',
	storeValue = true,
	defaultActive = false,
}

---@return Widget
function SwitchWidget:render()
	local label = self.props.label
	local switchGroup = self.props.switchGroup
	local storeValue = self.props.storeValue
	local defaultActive = self.props.defaultActive
	local content = self.props.content

	local switchToggleClasses = {'switch-toggle-container'}

	local toggleClasses = {'switch-toggle'}
	if defaultActive then
		table.insert(toggleClasses, 'switch-toggle-active')
	end

	local toggleAttributes = {
		['data-switch-group'] = switchGroup,
		['data-store-value'] = tostring(storeValue),
	}

	if self.props.collapsibleSelector then
		toggleAttributes['data-collapsible-selector'] = self.props.collapsibleSelector
	end

	local switchElement = Div{
		classes = switchToggleClasses,
		css = self.props.css,
		children = {
			Div{
				classes = toggleClasses,
				attributes = toggleAttributes,
				children = {
					Div{classes = {'switch-toggle-slider'}},
				},
			},
			Div{children = label},
		},
	}

	if not content then
		return switchElement
	end

	return Div{
		attributes = {
			['data-switch-group-container'] = switchGroup,
		},
		children = {
			switchElement,
			content,
		},
	}
end

return SwitchWidget
