---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/DetailedScore
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryDetailedScore: Widget
---@operator call(table): MatchSummaryDetailedScore
local MatchSummaryDetailedScore = Class.new(Widget)

---@return Widget
function MatchSummaryDetailedScore:render()
	local flipped = self.props.flipped
	local partialScores = Array.map(self.props.partialScores or {}, function(partialScore)
		local children = {partialScore.score or '', partialScore.icon}

		local styles = Array.append({},
			'brkts-popup-body-match-sidewins',
			partialScore.style,
			partialScore.icon and 'brkts-popup-body-match-sidewins-icon' or nil
		)

		return HtmlWidgets.Td{
			classes = styles,
			children = flipped and Array.reverse(children) or children,
		}
	end)

	return HtmlWidgets.Div{
		css = {['text-align'] = 'center', direction = flipped and 'rtl' or 'ltr'},
		children = HtmlWidgets.Table{
			css = {['line-height'] = '28px', float = flipped and 'right' or 'left'},
			children = {
				HtmlWidgets.Tr{
					children = {
						HtmlWidgets.Td{
							attributes = {rowspan = 2},
							css = {['font-size'] = '16px', width = '24px'},
							children = self.props.score
						},
						unpack(Array.filter(partialScores, function(_, i)
							return i % 2 == 1
						end))
					}
				},
				HtmlWidgets.Tr{
					children = Array.filter(partialScores, function(_, i)
						return i % 2 == 0
					end)
				}
			}
		}
	}
end

return MatchSummaryDetailedScore
