---
-- @Liquipedia
-- page=Module:Widget/POIDraft/POILabel
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Ordinal = Lua.import('Module:Ordinal')

local TeamDisplay = Lua.import('Module:Widget/TeamDisplay/Block')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local HtmlWidgets = Lua.import('Module:Widget/Html')

local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

---@class PoiLabelProps
---@field poiData PoiData
---@field draftArgs table<string, any>
---@field date string|number?
---@field isMobile boolean
---@field scale number

---@class PoiLabel: Widget
---@operator call(PoiLabelProps): PoiLabel
local PoiLabel = Class.new(Widget)

---@return Renderable
function PoiLabel:render()
	local props = self.props
	local poi = props.poiData
	local displayName = props.isMobile and poi.mobileName or poi.name

	local teamName = Logic.isNotEmpty(props.draftArgs[poi.name .. ' team'])
		and tostring(props.draftArgs[poi.name .. ' team'])
		or nil

	local content
	local classes

	if teamName then
		content = self:_renderPickedLabel(displayName, teamName, props.draftArgs[poi.name .. ' seed'])
		classes = {
			'brkts-opponent-hover',
			tostring(props.draftArgs[poi.name .. ' rotation']) == '1'
				and 'poi-label-rotation-one'
				or 'poi-label-rotation-two',
		}
	else
		content = self:_renderPoiNameNode(displayName)
		classes = {'brkts-opponent-hover', 'poi-label-rotation-two'}
	end

	local x = props.isMobile and (poi.mobileX or poi.x) or poi.x
	local y = props.isMobile and (poi.mobileY or poi.y) or poi.y

	return Div{
		css = {
			position = 'absolute',
			left = tostring(math.floor(x * props.scale)) .. 'px',
			top = tostring(math.floor(y * props.scale)) .. 'px',
			transform = 'translate(-50%, -50%)',
			['text-align'] = 'center',
		},
		children = {
			Div{
				classes = classes,
				attributes = teamName and {['aria-label'] = teamName} or nil,
				css = {
					['font-weight'] = 'bold',
					['line-height'] = '1',
				},
				children = content,
			},
		},
	}
end

---@private
---@param displayName string
---@param teamName string
---@param seed string|number|nil
---@return Renderable|Renderable[]
function PoiLabel:_renderPickedLabel(displayName, teamName, seed)
	if self.props.isMobile then
		return self:_renderPoiNameNode(displayName)
	end

	local seedNode = Logic.isNotEmpty(seed) and ('#' .. Ordinal.toOrdinal(seed)) or nil

	return WidgetUtil.collect(
		Div{
			css = {
				display = 'flex',
				['align-items'] = 'center',
				['justify-content'] = 'center',
				gap = '0.25em',
			},
			children = WidgetUtil.collect(
				seedNode,
				TeamDisplay{
					name = teamName,
					style = 'short',
					date = self.props.date,
				}
			),
		},
		self:_renderPoiNameNode(displayName)
	)
end

---@private
---@param displayName string
---@return Renderable
function PoiLabel:_renderPoiNameNode(displayName)
	return Span{
		css = {['font-size'] = '10pt'},
		children = displayName,
	}
end

return PoiLabel
