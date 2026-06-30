---
-- @Liquipedia
-- page=Module:Widget/ContentSwitch/Pill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class ContentSwitchPillProps
---@field tabs ContentSwitchTab[]
---@field variant? 'themed'|'generic'
---@field defaultActive? integer
---@field switchGroup string
---@field size? 'extrasmall'|'small'|'medium'
---@field storeValue? boolean
---@field css? table<string, string|number?>

---@param props ContentSwitchPillProps
---@return Renderable
local function ContentSwitchPill(props)
	local tabs = assert(props.tabs, 'ContentSwitchPill requires the tabs property to be set')
	local variant = props.variant
	local defaultActive = props.defaultActive or 1
	local switchGroup = assert(Logic.nilIfEmpty(props.switchGroup), 'ContentSwitchPill: missing \'switchGroup\' property')

	local tabOptions = Array.map(tabs, function(tab, index)
		local isActive = index == defaultActive
		local classes = {'switch-pill-option', 'toggle-area-button'}
		if isActive then
			table.insert(classes, 'switch-pill-option-active')
		end

		return Div{
			classes = classes,
			attributes = {
				['data-toggle-area-btn'] = tostring(index),
				['data-switch-value'] = tab.value or tostring(index),
			},
			children = Logic.emptyOr(tab.label, tostring(index)),
		}
	end)

	local switchPillClasses = {'switch-pill'}
	if variant == 'generic' then
		table.insert(switchPillClasses, 'switch-pill-generic')
	end
	if props.size == 'small' then
		table.insert(switchPillClasses, 'switch-pill-small')
	elseif props.size == 'extrasmall' then
		table.insert(switchPillClasses, 'switch-pill-extrasmall')
	end

	return Div{
		classes = {'switch-pill-container'},
		css = props.css,
		children = {
			Div{
				classes = switchPillClasses,
				attributes = {
					['data-switch-group'] = switchGroup,
					['data-store-value'] = Logic.readBool(props.storeValue) and 'true' or nil,
				},
				children = tabOptions,
			},
		},
	}
end

return Component.component(ContentSwitchPill)
