---
-- @Liquipedia
-- page=Module:Widget/Switch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@enum SwitchSyncLevel
local SwitchSyncLevel = {
	page = 'page',
	wiki = 'wiki',
	site = 'site',
}

---@class SwitchParameters
---@field label string
---@field switchGroup string
---@field storeValue boolean?
---@field defaultActive boolean?
---@field syncLevel SwitchSyncLevel?
---@field css table<string, string|number?>?
---@field content Renderable|Renderable[]?
---@field collapsibleSelector string?

---@type SwitchParameters
local defaultProps = {
	label = '',
	switchGroup = 'switch',
	storeValue = true,
	defaultActive = false,
	syncLevel = SwitchSyncLevel.site,
}

---@param props SwitchParameters
---@return VNode
local function SwitchWidget(props)
	local label = props.label
	local switchGroup = props.switchGroup
	local storeValue = props.storeValue
	local defaultActive = props.defaultActive
	local syncLevelInput = props.syncLevel
	local content = props.content

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

	if props.collapsibleSelector then
		toggleAttributes['data-collapsible-selector'] = props.collapsibleSelector
	end

	local switchElement = Div{
		classes = switchToggleClasses,
		css = props.css,
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

return Component.component(SwitchWidget, defaultProps)
