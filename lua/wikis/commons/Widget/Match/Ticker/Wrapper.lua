---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local Html = Lua.import('Module:Widget/Html')
local MatchCard = Lua.import('Module:Widget/Match/Card')
local HorizontalContainer = Lua.import('Module:Widget/Match/Ticker/HorizontalContainer')

---@param props {matches: table[], header: Renderable?, showInfoForEmptyResults: boolean, wrapperClasses: string[],
---hideTournament: boolean, displayGameIcons: boolean, onlyHighlightOnValue: string?, variant: 'vertical'|'horizontal'}
---@return Renderable?
local function MatchTickerWrapper(props)
	local matches = props.matches
	local hasMatches = not matches or #matches == 0
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
		return MatchCard{
			match = MatchGroupUtil.matchFromRecord(match),
			hideTournament = props.hideTournament,
			displayGameIcons = props.displayGameIcons,
			onlyHighlightOnValue = props.onlyHighlightOnValue,
			variant = props.variant == 'horizontal' and 'vertical' or nil,
			gameData = {
				asGame = match.asGame,
				gameIds = match.asGameIndexes,
				map = match.map,
				mapDisplayName = match.extradata and match.extradata.displayname or nil
			}
		}
	end)

	if props.variant == 'vertical' then
		return Html.Div{
			classes = props.wrapperClasses,
			children = Array.extend({header}, matchCards),
		}
	end

	return Html.Div{
		classes = props.wrapperClasses,
		children = Array.extend({header}, HorizontalContainer{children = matchCards}),
	}
end

return Component.component(MatchTickerWrapper)
