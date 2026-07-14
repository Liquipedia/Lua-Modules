---
-- @Liquipedia
-- page=Module:Widget/Match/Page/Footer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchPageFooterParameters
---@field comments VNode<MatchPageCommentParameters>[]?
---@field children Renderable|Renderable[]

---@param props MatchPageFooterParameters
---@return HtmlNode[]?
local function MatchPageFooter(props)
	local comments = props.comments
	local children = props.children
	if Logic.isEmpty(comments) and Logic.isEmpty(children) then return end
	return {
		Html.H3{children = 'Additional Information'},
		Html.Div{
			classes = { 'match-bm-match-additional' },
			children = WidgetUtil.collect(
				Logic.isNotEmpty(comments) and Html.Div{
					classes = {'match-bm-match-additional-comments'},
					children = comments
				} or nil,
				children
			)
		}
	}
end

return Component.component(MatchPageFooter)
