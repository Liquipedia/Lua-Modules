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
	matchesPortal = 'Liquipedia:Matches'
}

---@param props { matchesPortal: string?, displayGameIcons: boolean? }
---@return Renderable[]
local function MatchTicker(props)
	return {
		MatchTickerContainer{displayGameIcons = props.displayGameIcons},
		Html.Div{
			css = {
				['white-space'] = 'nowrap',
				display = 'block',
				margin = '0 10px',
				['font-size'] = '15px',
				['font-style'] = 'italic',
				['text-align'] = 'center',
				padding = '0.5rem 1rem',
			},
			children = { Link{ children = 'See more matches', link = props.matchesPortal} }
		}
	}
end

return Component.component(MatchTicker, defaultProps)
