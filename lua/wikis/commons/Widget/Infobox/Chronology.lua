---
-- @Liquipedia
-- page=Module:Widget/Infobox/Chronology
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
local InlineIconAndText = Lua.import('Module:Widget/Misc/InlineIconAndText')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Title = Lua.import('Module:Widget/Infobox/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ChronologyDisplayWidget: Widget
---@operator call(table): ChronologyDisplayWidget
---@field props {links: {previous: {link:string, text: string}?, next: {link:string, text: string}?}[],
---title: string, showTitle: boolean}
local Chronology = Class.new(Widget)
Chronology.defaultProps = {
	title = 'Chronology',
	showTitle = false,
}

---@return Widget?
function Chronology:render()
	local links = self.props.links
	if Logic.isEmpty(links) then
		return
	end

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			Logic.readBool(self.props.showTitle) and Title{children = self.props.title} or nil,
			Array.map(self.props.links, Chronology._createChronologyRow)
		)
	}
end

---@param links {previous: {link:string, text: string}?, next: {link:string, text: string}?}
---@return Widget?
function Chronology._createChronologyRow(links)
	if Logic.isEmpty(links) then return end

	local makeCell = function(mode)
		if not links[mode] then return end
		return Div{
			classes = {'infobox-cell-2', 'infobox-text-' .. (mode == 'previous' and 'left' or 'right')},
			children = {
				InlineIconAndText{
					link = links[mode].link,
					text = links[mode].text,
					icon = IconFa{
						iconName = mode,
						link = links[mode].link,
					},
					flipped = mode ~= 'previous',
				}
			}
		}
	end

	return Div{
		children = {
			makeCell('previous') or Div{classes = {'infobox-cell-2'}},
			makeCell('next'),
		}
	}
end

return Chronology
