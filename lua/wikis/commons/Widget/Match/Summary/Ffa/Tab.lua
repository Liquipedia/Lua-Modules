---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/Tab
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@param props {matchId: string, idx: integer, children?: Renderable|Renderable[]}
---@return HtmlNode
local function MatchSummaryFfaTab(props)
	return Html.Div{
		classes = {'panel-content'},
		attributes = {
			['data-js-battle-royale'] = 'panel-content',
			id = props.matchId .. 'panel' .. props.idx,
		},
		children = props.children,
	}
end

return Component.component(MatchSummaryFfaTab)
