---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/MatchComment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Break = Lua.import('Module:Widget/Match/Summary/Break')

---@param props {children: Renderable[]}
---@return VNode?
local function MatchSummaryMatchMatchComment(props)
	if Logic.isEmpty(props.children) then
		return
	end

	return Html.Div{
		classes = {'brkts-popup-comment'},
		children = Array.interleave(props.children, Break{})
	}
end

return Component.component(MatchSummaryMatchMatchComment)
