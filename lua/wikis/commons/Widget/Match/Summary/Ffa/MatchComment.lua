---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/MatchComment
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local Html = Lua.import('Module:Widget/Html')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@param props {match: FFAMatchGroupUtilMatch}
---@return VNode?
local function MatchSummaryFfaMatchComment(props)
	local comment = props.match.comment
	if Logic.isEmpty(comment) then return nil end
	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = {{
		icon = IconWidget{iconName = 'comment'},
		content = Html.Span{children = comment},
	}}}
end

return Component.component(MatchSummaryFfaMatchComment)
