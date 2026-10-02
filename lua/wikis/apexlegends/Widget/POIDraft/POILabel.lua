---
-- @Liquipedia
-- page=Module:Widget/POIDraft/POILabel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Ordinal = Lua.import('Module:Ordinal')

local Component = Lua.import('Module:Widget/Component')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local TeamDisplay = Lua.import('Module:Widget/TeamDisplay/Block')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

local Helpers = {}

---@class PoiLabelProps
---@field poiData PoiData
---@field draftArgs table<string, any>
---@field date string|number?
---@field isMobile boolean
---@field scale number

---@private
---@param displayName string
---@return HtmlNode
function Helpers._renderPoiNameNode(displayName)
	return Span {
		css = { ['font-size'] = '10pt' },
		children = displayName,
	}
end

---@private
---@param props PoiLabelProps
---@param displayName string
---@param teamName string
---@param seed string|number|nil
---@return Renderable|Renderable[]
function Helpers._renderPickedLabel(props, displayName, teamName, seed)
	if props.isMobile then
		return Helpers._renderPoiNameNode(displayName)
	end

	local seedNode = Logic.isNotEmpty(seed) and ('#' .. Ordinal.toOrdinal(seed)) or nil

	return WidgetUtil.collect(
		Div {
			css = {
				display = 'flex',
				['align-items'] = 'center',
				['justify-content'] = 'center',
				gap = '0.25em',
			},
			children = WidgetUtil.collect(
				seedNode,
				TeamDisplay {
					name = teamName,
					style = 'short',
					date = props.date,
				}
			),
		},
		Helpers._renderPoiNameNode(displayName)
	)
end

---@param props PoiLabelProps
---@return HtmlNode
local function PoiLabel(props)
	local poi = props.poiData
	local displayName = props.isMobile and poi.mobileName or poi.name

	local teamName = Logic.isNotEmpty(props.draftArgs[poi.name .. ' team'])
		and tostring(props.draftArgs[poi.name .. ' team'])
		or nil

	local content
	local classes

	if teamName then
		content = Helpers._renderPickedLabel(props, displayName, teamName, props.draftArgs[poi.name .. ' seed'])
		classes = {
			'brkts-opponent-hover',
			tostring(props.draftArgs[poi.name .. ' rotation']) == '1'
			and 'poi-label-rotation-one'
			or 'poi-label-rotation-two',
		}
	else
		content = Helpers._renderPoiNameNode(displayName)
		classes = { 'brkts-opponent-hover', 'poi-label-rotation-two' }
	end

	local x = props.isMobile and (poi.mobileX or poi.x) or poi.x
	local y = props.isMobile and (poi.mobileY or poi.y) or poi.y

	return Div {
		css = {
			position = 'absolute',
			left = tostring(math.floor(x * props.scale)) .. 'px',
			top = tostring(math.floor(y * props.scale)) .. 'px',
			transform = 'translate(-50%, -50%)',
			['text-align'] = 'center',
		},
		children = {
			Div {
				classes = classes,
				attributes = teamName and { ['aria-label'] = teamName } or nil,
				css = {
					['font-weight'] = 'bold',
					['line-height'] = '1',
				},
				children = content,
			},
		},
	}
end

return Component.component(PoiLabel)
