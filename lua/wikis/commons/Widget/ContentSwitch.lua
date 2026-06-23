---
-- @Liquipedia
-- page=Module:Widget/ContentSwitch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local SwitchPill = Lua.import('Module:Widget/ContentSwitch/Pill')
local Div = Html.Div

---@class ContentSwitchTab
---@field label? Renderable|Renderable[]
---@field value? string
---@field content? Renderable|Renderable[]

---@class ContentSwitchProps: ContentSwitchPillProps
---@field classes? string[]

local defaultProps = {
	variant = 'generic',
	defaultActive = 1,
	size = 'extrasmall',
	storeValue = true,
}

---@param props ContentSwitchProps
---@return Renderable|Renderable[]
local function ContentSwitch(props)
	local tabs = assert(props.tabs, 'ContentSwitch requires at least the tabs property to be set')
	local defaultActive = props.defaultActive

	if #tabs < 2 then
		return (tabs[1] or {}).content
	end

	local contentAreas = Array.map(tabs, function(tab, index)
		local isActive = index == defaultActive
		return Div{
			attributes = {
				['data-toggle-area-content'] = tostring(index),
			},
			classes = {isActive and 'toggle-area-content-active' or 'toggle-area-content-inactive'},
			children = tab.content,
		}
	end)

	return Div{
		classes = {'toggle-area', 'toggle-area-' .. tostring(defaultActive)},
		attributes = {['data-toggle-area'] = tostring(defaultActive)},
		children = {
			SwitchPill(props),
			Div{
				classes = {'content-switch-content-container'},
				children = contentAreas,
			},
		},
	}
end

return Component.component(ContentSwitch, defaultProps)
