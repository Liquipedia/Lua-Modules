-- @Liquipedia
-- page=Module:Widget/ContentSwitch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ContentSwitchTab
---@field label string
---@field value string

---@class ContentSwitchParameters
---@field tabs ContentSwitchTab[]
---@field variant 'themed'|'generic'
---@field defaultActive integer
---@field switchGroup string
---@field classes string[]?

---@class ContentSwitch: Widget
---@operator call(ContentSwitchParameters): ContentSwitch
local ContentSwitch = Class.new(Widget)
ContentSwitch.defaultProps = {
	tabs = {},
	variant = 'themed',
	defaultActive = 1,
	switchGroup = 'contentSwitch',
}

---@return Widget
function ContentSwitch:render()
	local tabs = self.props.tabs
	local variant = self.props.variant
	local defaultActive = self.props.defaultActive
	local switchGroup = self.props.switchGroup

	local tabOptions = Array.map(tabs, function(tab, index)
		local isActive = index == defaultActive
		local classes = {'switch-pill-option', 'toggle-area-button'}
		if isActive then
			table.insert(classes, 'switch-pill-active')
		end

		return Div{
			classes = classes,
			attributes = {
				['data-toggle-area-btn'] = tostring(index),
				['data-switch-value'] = tab.value or tostring(index),
			},
			children = tab.label or tostring(index),
		}
	end)

	local switchPillClasses = {'switch-pill'}
	if variant == 'generic' then
		table.insert(switchPillClasses, 'switch-pill-generic')
	end

	return Div{
		classes = {'switch-pill-container'},
		children = {
			Div{
				classes = switchPillClasses,
				attributes = {
					['data-switch-group'] = switchGroup,
					['data-store-value'] = 'true',
				},
				children = tabOptions,
			},
		},
	}
end

