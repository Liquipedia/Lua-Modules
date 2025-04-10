---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/GameDetails
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')
local Page = require('Module:Page')

local Widget = Lua.import('Module:Widget')
local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchSummaryFfaGameDetails: Widget
---@operator call(table): MatchSummaryFfaGameDetails
local MatchSummaryFfaGameDetails = Class.new(Widget)

---@return Widget
function MatchSummaryFfaGameDetails:render()
	local game = self.props.game
	assert(game, 'No game provided')

	local casters = Array.map(game.extradata.casters, function(caster)
		if not caster.name then
			return nil
		end

		local casterLink = Link{children = caster.displayName, link = caster.name}
		if not caster.flag then
			return casterLink
		end

		return HtmlWidgets.Fragment{children = {
			Flags.Icon(caster.flag),
			'&nbsp;',
			casterLink,
		}}
	end)

	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = WidgetUtil.collect(
		{
			icon = CountdownIcon{game = game},
			content = GameCountdown{game = game},
		},
		game.map and {
			icon = IconWidget{iconName = 'map'},
			content = HtmlWidgets.Span{children = Page.makeInternalLink(game.map)},
		} or nil,
		casters and {
			icon = IconWidget{iconName = 'casters'},
			content = HtmlWidgets.Span{children = Array.interleave(casters, ', ')},
		} or nil,
		game.comment and {
			icon = IconWidget{iconName = 'comment'},
			content = HtmlWidgets.Span{children = game.comment},
		} or nil
	)}
end

return MatchSummaryFfaGameDetails
