---
-- @Liquipedia
-- page=Module:Widget/Infobox/Core
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Variables = Lua.import('Module:Variables')

local Component = Lua.import('Module:Widget/Component')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local WarningBoxGroup = Lua.import('Module:Widget/WarningBox/Group')

---@class InfoboxCoreProps
---@field children Renderable|Renderable[]
---@field forceDarkMode? boolean
---@field gameName string
---@field infoboxType? string
---@field topContent? Renderable|Renderable[]
---@field bottomContent? Renderable|Renderable[]
---@field warnings? (string|number)[]

---@param props InfoboxCoreProps
---@return string
local function Infobox(props)
	local firstInfobox = not Variables.varDefault('has_infobox')
	Variables.varDefine('has_infobox', 'true')

	local topContent = Div{
		classes = {'fo-nttax-infobox-topcontent'},
		children = props.topContent
	}
	local adbox = Div{classes = {'fo-nttax-infobox-adbox'}, children = {mw.getCurrentFrame():preprocess('<adbox />')}}
	local content = Div{classes = {'fo-nttax-infobox'}, children = props.children}
	local bottomContent = Div{children = props.bottomContent}

	return AnalyticsWidget{
		analyticsName = 'Infobox',
		analyticsProperties = {
			['infobox-type'] = props.infoboxType
		},
		classes = {'fo-nttax-infobox-container'},
		children = WidgetUtil.collect(
			Div{
				classes = {
					'fo-nttax-infobox-wrapper',
					'infobox-' .. props.gameName:lower(),
					props.forceDarkMode and 'infobox-darkmodeforced' or nil,
				},
				children = WidgetUtil.collect(
					content,
					firstInfobox and adbox or nil,
					bottomContent
				)
			},
			topContent,
			WarningBoxGroup{data = props.warnings}
		)
	}
end

return Component.component(Infobox)
