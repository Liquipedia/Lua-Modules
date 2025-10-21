---
-- @Liquipedia
-- page=Module:Widget/Infobox/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Variables = Lua.import('Module:Variables')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Fragment = HtmlWidgets.Fragment
local WarningBoxGroup = Lua.import('Module:Widget/WarningBox/Group')

---@class Infobox: Widget
---@operator call(table): Infobox
---@field props table
local Infobox = Class.new(Widget)

---@return string
function Infobox:render()
	local firstInfobox = not Variables.varDefault('has_infobox')
	Variables.varDefine('has_infobox', 'true')

	local adbox = Div{classes = {'fo-nttax-infobox-adbox'}, children = {mw.getCurrentFrame():preprocess('<adbox />')}}
	local content = Div{classes = {'fo-nttax-infobox'}, children = self.props.children}
	local bottomContent = Div{children = self.props.bottomContent}

	local analyticsProps = {
		analyticsName = 'Infobox',
		children = {
			Fragment{children = WidgetUtil.collect(
				Div{
					classes = {
						'fo-nttax-infobox-wrapper',
						'infobox-' .. self.props.gameName:lower(),
						self.props.forceDarkMode and 'infobox-darkmodeforced' or nil,
					},
					children = WidgetUtil.collect(
						content,
						firstInfobox and adbox or nil,
						bottomContent
					)
				},
				WarningBoxGroup{data = self.props.warnings}
			)}
		}
	}

	if self.props.infoboxType then
		analyticsProps.analyticsProperties = {
			['infobox-type'] = self.props.infoboxType
		}
	end

	return AnalyticsWidget(analyticsProps)
end

return Infobox
