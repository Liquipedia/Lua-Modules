---
-- @Liquipedia
-- page=Module:Widget/ContentSwitch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ContentSwitchTab
---@field label Renderable|Renderable[]
---@field value string
---@field content Renderable|Renderable[]

---@class ContentSwitchParameters
---@field tabs ContentSwitchTab[]
---@field variant 'themed'|'generic'
---@field defaultActive integer
---@field switchGroup string
---@field classes string[]?
---@field size 'small'|'medium'
---@field storeValue boolean
---@field css table?

---@class ContentSwitch: Widget
---@operator call(ContentSwitchParameters): ContentSwitch
---@field props ContentSwitchParameters
local ContentSwitch = Class.new(Widget)
ContentSwitch.defaultProps = {
	tabs = {},
	variant = 'themed',
	defaultActive = 1,
	size = 'medium',
	storeValue = true,
}

---@return Widget
function ContentSwitch:render()
	local tabs = assert(self.props.tabs, 'ContentSwitch requires at least the tabs property to be set')
	local variant = self.props.variant
	local defaultActive = self.props.defaultActive
	local switchGroup = self:assertExistsAndCopy(self.props.switchGroup)

	if #tabs < 2 then
		return HtmlWidgets.Fragment{children = (tabs[1] or {}).content}
	end

	local tabOptions = Array.map(tabs, function(tab, index)
		local isActive = index == defaultActive
		local classes = {'switch-pill-option', 'toggle-area-button'}
		if self.props.size == 'small' then
			table.insert(classes, 'switch-pill-small')
		end
		if isActive then
			table.insert(classes, 'switch-pill-active')
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

	local switchPillClasses = {'switch-pill'}
	if variant == 'generic' then
		table.insert(switchPillClasses, 'switch-pill-generic')
	end

	return Div{
		classes = {'toggle-area', 'toggle-area-' .. tostring(defaultActive)},
		attributes = {['data-toggle-area'] = tostring(defaultActive)},
		children = {
			Div{
				classes = {'switch-pill-container'},
				css = self.props.css,
				children = {
					Div{
						classes = switchPillClasses,
						attributes = {
							['data-switch-group'] = switchGroup,
							['data-store-value'] = Logic.readBool(self.props.storeValue) and 'true' or nil,
						},
						children = tabOptions,
					},
				},
			},
			Div{
				classes = {'content-switch-content-container'},
				children = contentAreas,
			},
		},
	}
end

return ContentSwitch
