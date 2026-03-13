---
-- @Liquipedia
-- page=Module:Widget/Switch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@enum SwitchSyncLevel
local SwitchSyncLevel = {
	page = 'page',
	wiki = 'wiki',
	site = 'site',
}

---@class SwitchParameters
---@field label string
---@field switchGroup string
---@field storeValue boolean
---@field defaultActive boolean
---@field syncLevel 'page'|'wiki'|'site'
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
	syncLevel = 'site',
}

---@return Widget
function SwitchWidget:render()
	local label = self.props.label
	local switchGroup = self.props.switchGroup
	local storeValue = self.props.storeValue
	local defaultActive = self.props.defaultActive
	local syncLevelInput = self.props.syncLevel
	local content = self.props.content

	assert(Table.includes(SwitchSyncLevel, syncLevelInput), 'Invalid syncLevel: ' .. tostring(syncLevelInput))
	local syncLevel = syncLevelInput

	local switchToggleClasses = {'switch-toggle-container'}

	local toggleClasses = {'switch-toggle'}
	if defaultActive then
		table.insert(toggleClasses, 'switch-toggle-active')
	end

	local toggleAttributes = {
		['data-switch-group'] = switchGroup,
		['data-store-value'] = tostring(storeValue),
		['data-sync-level'] = syncLevel,
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
