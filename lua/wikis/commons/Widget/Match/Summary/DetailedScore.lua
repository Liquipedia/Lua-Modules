---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/DetailedScore
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class MatchSummaryDetailedScoreProps
---@field partialScores {style: string?, icon: Renderable?, score: Renderable?}[]
---@field flipped boolean?
---@field score Renderable?

---@param props MatchSummaryDetailedScoreProps
---@return VNode
local function MatchSummaryDetailedScore(props)
	local flipped = props.flipped
	local partialScores = Array.map(props.partialScores or {}, function(partialScore)
		local children = {partialScore.score or '', partialScore.icon}

		local styles = Array.extend(
			'brkts-popup-body-detailed-score',
			partialScore.style,
			partialScore.icon and 'brkts-popup-body-detailed-score-icon' or nil
		)

		return Html.Span{
			classes = styles,
			children = children,
		}
	end)

	return Html.Div{
		classes = {
			'brkts-popup-body-detailed-scores-container',
			flipped and 'flipped' or nil,
		},
		children = {
			Html.Div{
				classes = {'brkts-popup-body-detailed-scores-main-score'},
				children = props.score
			},
			Html.Div{
				classes = {'brkts-popup-body-detailed-scores'},
				children = partialScores
			}
		}
	}
end

return Component.component(MatchSummaryDetailedScore)
