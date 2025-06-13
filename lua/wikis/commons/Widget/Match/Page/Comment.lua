---
-- @Liquipedia
-- page=Module:Widget/Match/Page/Comment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class MatchPageCommentParameters
---@field children (string|Html|Widget|nil)|(string|Html|Widget|nil)[]

---@class MatchPageComment: Widget
---@operator call(MatchPageCommentParameters): MatchPageComment
---@field props MatchPageCommentParameters
local MatchPageComment = Class.new(Widget)

---@return Widget[]
function MatchPageComment:render()
	return {
		Div{
			classes = { 'match-bm-match-additional-comment' },
			children = WidgetUtil.collect(self.props.children)
		}
	}
end

return MatchPageComment
