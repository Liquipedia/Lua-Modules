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
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MatchSummaryFfaMatchInformation = {}

---@param props FFAMatchGroupUtilMatch
---@return VNode?
function MatchSummaryFfaMatchInformation.render(props)
	local items = WidgetUtil.collect(
		MatchSummaryFfaMatchInformation._getMvpItem(props.extradata.mvp),
		MatchSummaryFfaMatchInformation._getCasterItem(props.extradata.casters),
		MatchSummaryFfaMatchInformation._getCommentItem(props.comment)
	)
	if #items == 0 then return end
	return ContentItemContainer{
		collapsible = #items > 1,
		collapsed = #items > 1,
		contentClass = 'panel-content__game-schedule',
		title = 'Match Information',
		items = items
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
---@param mvp {players: MatchGroupMvpPlayer[], points: integer?}?
---@return MatchSummaryFfaContentItem?
function MatchSummaryFfaMatchInformation._getMvpItem(mvp)
	if Logic.isEmpty(mvp) then
		return
	end
	---@cast mvp -nil
	if Logic.isEmpty(mvp.players) then
		return
	end
	local points = tonumber(mvp.points)
	local players = Array.map(mvp.players, function(inputPlayer)
		local player = type(inputPlayer) ~= 'table' and {name = inputPlayer, displayname = inputPlayer} or inputPlayer

		return Html.Fragment{children = {
			Link{link = player.name, children = player.displayname},
			player.comment and ' (' .. player.comment .. ')' or nil
		}}
	end)
	return {
		icon = IconWidget{iconName = 'mvp', color = 'bright-sun-0-text', size = '0.875rem'},
		title = 'MVP:',
		content = Html.Span{children = Array.extend(
			players,
			points and points > 1 and (' (' .. points .. ' pts)') or nil
		)}
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
