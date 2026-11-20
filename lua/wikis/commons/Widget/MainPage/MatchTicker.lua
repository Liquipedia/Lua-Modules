---
-- @Liquipedia
-- page=Module:Widget/MainPage/MatchTicker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local MatchTickerContainer = Lua.import('Module:Widget/Match/Ticker/FilterableContainer')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

local defaultProps = {
	matchesPortal = 'Liquipedia:Matches',
	showMatchesPortal = true,
}

---@param props { matchesPortal: string?, displayGameIcons: boolean?, showMatchesPortal: boolean? }
---@return Renderable[]
local function MainPageMatchTicker(props)
	return {
		MatchTickerContainer{displayGameIcons = props.displayGameIcons},
		props.showMatchesPortal and Html.Div{
			css = {
				['white-space'] = 'nowrap',
				display = 'block',
				margin = '0 10px',
				['font-size'] = '15px',
				['font-style'] = 'italic',
				['text-align'] = 'center',
				padding = '0.5rem 1rem',
			},
			children = Html.Div{
				classes = {'mobile-only'},
				Link{ children = 'See more matches', link = props.matchesPortal}
			}
		} or nil,
	}
end

return Component.component(MainPageMatchTicker, defaultProps)
