---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/DetailedScore
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

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

		local styles = Array.extend(
			'brkts-popup-body-detailed-score',
			partialScore.style,
			partialScore.icon and 'brkts-popup-body-detailed-score-icon' or nil
		)

		return HtmlWidgets.Span{
			classes = styles,
			children = children,
		}
	end)

	return HtmlWidgets.Div{
		classes = {
			'brkts-popup-body-detailed-scores-container',
			flipped and 'flipped' or nil,
		},
		children = {
			HtmlWidgets.Div{
				classes = {'brkts-popup-body-detailed-scores-main-score'},
				children = self.props.score
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-body-detailed-scores'},
				children = partialScores
			}
		}
	}
end

return MatchSummaryDetailedScore
