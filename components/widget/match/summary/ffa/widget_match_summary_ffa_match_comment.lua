---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/MatchComment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Widget = Lua.import('Module:Widget')

---@class MatchSummaryFfaMatchComment: Widget
---@operator call(table): MatchSummaryFfaHeader
local MatchSummaryFfaMatchComment = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaMatchComment:render()
	local comment = self.props.match.comment
	if Logic.isEmpty(comment) then return nil end
	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = {{
		icon = IconWidget{iconName = 'comment'},
		content = HtmlWidgets.Span{children = comment},
	}}}
end

return MatchSummaryFfaMatchComment
