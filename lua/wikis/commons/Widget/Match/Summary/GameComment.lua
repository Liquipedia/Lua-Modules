---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameComment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchSummaryBreak = Lua.import('Module:Widget/Match/Summary/Break')

---@param props {classes: string[]?, children: Renderable|Renderable[]?}
---@return VNode[]?
local function MatchSummaryGameComment(props)
	if Logic.isEmpty(props.children) then
		return nil
	end
	return {
		MatchSummaryBreak{},
		Html.Div{
			css = {margin = 'auto', ['max-width'] = '100%'},
			classes = props.classes,
			children = props.children
		},
	}
end

return Component.component(MatchSummaryGameComment)
