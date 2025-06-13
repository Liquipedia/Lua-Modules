---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/MatchInformation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchSummaryFfaMatchInformation: Widget
---@operator call(table): MatchSummaryFfaMatchInformation
local MatchSummaryFfaMatchInformation = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaMatchInformation:render()
	local items = WidgetUtil.collect(
		self:_getMvpItem(),
		self:_getCasterItem(),
		self:_getCommentItem()
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
---@return MatchSummaryFfaContentItem?
function MatchSummaryFfaMatchInformation:_getCommentItem()
	local comment = self.props.comment
	if not comment then return end
	return {
		icon = IconWidget{iconName = 'comment'},
		content = HtmlWidgets.Span{children = comment},
	}
end

---@private
---@return MatchSummaryFfaContentItem?
function MatchSummaryFfaMatchInformation:_getMvpItem()
	local mvp = self.props.extradata.mvp
	if Logic.isEmpty(mvp) then return
	elseif Logic.isEmpty(mvp.players) then return end
	local points = tonumber(mvp.points)
	local players = Array.map(mvp.players, function(inputPlayer)
		local player = type(inputPlayer) ~= 'table' and {name = inputPlayer, displayname = inputPlayer} or inputPlayer

		return HtmlWidgets.Fragment{children = {
			Link{link = player.name, children = player.displayname},
			player.comment and ' (' .. player.comment .. ')' or nil
		}}
	end)
	return {
		icon = IconWidget{iconName = 'mvp', color = 'bright-sun-0-text', size = '0.875rem'},
		title = 'MVP:',
		content = HtmlWidgets.Span{children = Array.extend(
			players,
			points and points > 1 and (' (' .. points .. ' pts)') or nil
		)}
	}
end

---@private
---@return MatchSummaryFfaContentItem?
function MatchSummaryFfaMatchInformation:_getCasterItem()
	local rawCasters = self.props.extradata.casters
	if Logic.isEmpty(rawCasters) then return end

	local casters = DisplayHelper.createCastersDisplay(rawCasters)

	if #casters == 0 then return end
	return {
		icon = IconWidget{iconName = 'casters', size = '0.875rem', hover = 'Caster' .. (#casters > 1 and 's' or '')},
		content = HtmlWidgets.Span{children = Array.interleave(casters, ', ')}
	}
end

return MatchSummaryFfaMatchInformation
