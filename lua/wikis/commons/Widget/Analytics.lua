---
-- @Liquipedia
-- page=Module:Widget/Analytics
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@class AnalyticsWidgetParameters
---@field analyticsName string?
---@field analyticsProperties table<string, string>?
---@field classes string[]?
---@field children Renderable|Renderable[]?
---@field css table<string, string|integer?>?

---@param props AnalyticsWidgetParameters
---@return Renderable|Renderable[]?
local function AnalyticsWidget(props)
	local analyticsName = props.analyticsName

	if analyticsName then
		local attributes = {
			['data-analytics-name'] = analyticsName
		}

		if props.analyticsProperties then
			Table.iter.forEachPair(props.analyticsProperties, function(key, value)
				attributes['data-analytics-' .. key] = value
			end)
		end

		return Div{
			attributes = attributes,
			classes = props.classes,
			css = props.css,
			children = props.children
		}
	end

	if Logic.isEmpty(props.classes) then
		return props.children
	end

	return Div{
		classes = props.classes,
		children = props.children
	}
end

return Component.component(AnalyticsWidget)

