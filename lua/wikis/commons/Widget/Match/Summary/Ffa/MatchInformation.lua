---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/MatchInformation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local Html = Lua.import('Module:Widget/Html')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local MatchSummaryFfaMvp = Lua.import('Module:Widget/Match/Summary/Ffa/Mvp')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MatchSummaryFfaMatchInformation = {}

---@param props FFAMatchGroupUtilMatch
---@return VNode[]
function MatchSummaryFfaMatchInformation.render(props)
	return {
		ContentItemContainer{
			collapsible = true,
			collapsed = true,
			contentClass = 'panel-content__game-schedule',
			title = 'Match Information',
			items = WidgetUtil.collect(
				MatchSummaryFfaMatchInformation._getCasterItem(props.extradata.casters),
				MatchSummaryFfaMatchInformation._getCommentItem(props.comment)
			)
		},
		MatchSummaryFfaMvp(props.extradata.mvp),
	}
end

---@private
---@param comment string?
---@return MatchSummaryFfaContentItem?
function MatchSummaryFfaMatchInformation._getCommentItem(comment)
	if not comment then return end
	return {
		icon = IconWidget{iconName = 'comment'},
		content = Html.Span{children = comment},
	}
end

---@private
---@param rawCasters {name:string, displayName: string, flag: string?}[]?
---@return MatchSummaryFfaContentItem?
function MatchSummaryFfaMatchInformation._getCasterItem(rawCasters)
	if Logic.isEmpty(rawCasters) then return end
	---@cast rawCasters -nil
	local casters = DisplayHelper.createCastersDisplay(rawCasters)

	if #casters == 0 then return end
	return {
		icon = IconWidget{iconName = 'casters', size = '0.875rem', hover = 'Caster' .. (#casters > 1 and 's' or '')},
		content = Html.Span{children = Array.interleave(casters, ', ')}
	}
end

return Component.component(MatchSummaryFfaMatchInformation.render)
