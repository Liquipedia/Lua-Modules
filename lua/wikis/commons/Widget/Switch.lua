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

---@class Switch: Widget
---@operator call(SwitchParameters): Switch
local Switch = Class.new(Widget)
Switch.defaultProps = {
	label = '',
	switchGroup = 'switch',
	storeValue = true,
	defaultActive = false,
}

---@return Widget
function Switch:render()
	local label = self.props.label
	local switchGroup = self.props.switchGroup
	local storeValue = self.props.storeValue
	local defaultActive = self.props.defaultActive

	local switchToggleClasses = {'switch-toggle-container'}

	local toggleClasses = {'switch-toggle'}
	if defaultActive then
		table.insert(toggleClasses, 'switch-toggle-active')
	end

	return Div{
		classes = switchToggleClasses,
		css = self.props.css or {},
		children = {
			Div{
				classes = toggleClasses,
				attributes = {
					['data-switch-group'] = switchGroup,
					['data-store-value'] = tostring(storeValue),
				},
				children = {
					Div{classes = {'switch-toggle-slider'}},
				},
			},
			Div{children = label},
		},
	}
end

return Switch
