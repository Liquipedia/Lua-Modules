---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')

local CarouselContent = Lua.import('Module:Widget/Basic/Carousel/Content')
local Html = Lua.import('Module:Widget/Html')
local MatchTickerCard = Lua.import('Module:Widget/Match/Ticker/Card')
local HorizontalContainer = Lua.import('Module:Widget/Match/Ticker/HorizontalContainer')

---@param props {matches: {match: MatchGroupUtilMatch, gameData: MatchTickerGameData?}[],
---header: Renderable?, showInfoForEmptyResults: boolean, wrapperClasses: string[],
---hideTournament: boolean, displayGameIcons: boolean, onlyHighlightOnValue: string?,
---variant: 'vertical'|'horizontal'|'carousel'}
---@return Renderable?
local function MatchTickerWrapper(props)
	local matches = props.matches
	local hasMatches = matches and #matches > 0
	if not hasMatches and not props.showInfoForEmptyResults then
		return
	end
	local header = props.header

	if not hasMatches then
		return Html.Div{
			classes = props.wrapperClasses,
			css = {['text-align'] = 'center'},
			children = Array.extend({header}, {'No Results found.'}),
		}
	end

	local matchCards = Array.map(matches, function(match)
		return MatchTickerCard{
			match = match.match,
			hideTournament = props.hideTournament,
			displayGameIcons = props.displayGameIcons,
			onlyHighlightOnValue = props.onlyHighlightOnValue,
			-- The date is shown in the group header
			countdownFormat = (props.variant == 'carousel' or props.variant == 'horizontal') and 'minimal' or nil,
			gameData = match.gameData
		}
	end)

	if props.variant == 'vertical' then
		return Html.Div{
			classes = props.wrapperClasses,
			children = Array.extend({header}, matchCards),
		}
	end

	-- Bare scrollable card list; the surrounding `.carousel` (and its controls) is provided by the caller.
	-- Item widths are left to the stylesheet, so the caller can switch to a stacked list on small screens.
	if props.variant == 'carousel' then
		return Html.Div{
			classes = props.wrapperClasses,
			children = Array.extend({header}, CarouselContent{
				classes = {'match-ticker-carousel'},
				children = matchCards,
				itemWidth = false,
				gap = '0',
			}),
		}
	end

	return HorizontalContainer{children = matchCards}
end

return Component.component(MatchTickerWrapper)
