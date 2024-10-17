---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Fragment, Header = HtmlWidgets.Div, HtmlWidgets.Fragment, HtmlWidgets.Header
local Link = Lua.import('Module:Widget/Basic/Link')
local MatchPageFooterSection = Lua.import('Module:Widget/Match/Page/Footer/Section')

---@class MatchPageFooter: Widget
---@operator call(table): MatchPageFooter
local MatchPageFooter = Class.new(Widget)
MatchPageFooter.defaultProps = {
	flipped = false,
}

---@return Widget[]?
function MatchPageFooter:render()
	return Fragment{children = {
		Header{level = 3, children = 'Additional Information'},
		Div{
			classes = {'match-bm-match-additional'},
			children = WidgetUtil.collect(
				self.props.vods and MatchPageFooterSection{header = 'VODs', children = self.props.vods} or nil,
				self.props.links and MatchPageFooterSection{header = 'Socials', children = Array.map(self.props.links, function(link)
					return '[['.. link.icon .. '|link='.. link.link .. '|15px|'.. link.text .. ']]'
				end)} or nil,
				self.props.patch and MatchPageFooterSection{header = 'Patch', children =
					Link{link = 'Version ' .. self.props.patch, children = 'Version ' .. self.props.patch}
				} or nil
			)
		}
	}}
end

return MatchPageFooter
