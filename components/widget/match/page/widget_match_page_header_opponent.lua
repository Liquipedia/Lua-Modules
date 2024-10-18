---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Header/Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPageHeaderOpponent: Widget
---@operator call(table): MatchPageHeaderOpponent
local MatchPageHeaderOpponent = Class.new(Widget)

---@return Widget[]?
function MatchPageHeaderOpponent:render()
	if not self.props.template or not self.props.page or not self.props.name or not self.props.shortname then
		return nil
	end
	return Div{
		classes = {'match-bm-match-header-team'},
		children = {
			self.props.icon or '',
			Div{
				classes = {'match-bm-match-header-team-group'},
				children = {
					Div{
						classes = {'match-bm-match-header-team-long'},
						children = {Link{link = self.props.page, children = self.props.name}},
					},
					Div{
						classes = {'match-bm-match-header-team-short'},
						children = {Link{link = self.props.page, children = self.props.shortname}},
					},
					Div{
						classes = {'match-bm-lol-match-header-round-results'},
						children = Array.map(self.props.seriesDots or {}, function(dot)
							return Div{
								classes = {'match-bm-lol-match-header-round-result', 'result--' .. dot},
							}
						end),
					}
				}
			}
		},
	}
end

return MatchPageHeaderOpponent
