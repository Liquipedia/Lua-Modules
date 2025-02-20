---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/Mvp
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local Widget = Lua.import('Module:Widget')

---@class MatchSummaryFfaMvp: Widget
---@operator call(table): MatchSummaryFfaHeader
local MatchSummaryFfaMvp = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaMvp:render()
	if Logic.isEmpty(self.props.players) then
		return nil
	end
	local points = tonumber(self.props.points)
	local players = Array.map(self.props.players, function(inputPlayer)
		local player = type(inputPlayer) ~= 'table' and {name = inputPlayer, displayname = inputPlayer} or inputPlayer

		return HtmlWidgets.Fragment{children = {
			Link{link = player.name, children = player.displayname},
			player.comment and ' (' .. player.comment .. ')' or nil
		}}
	end)

	return ContentItemContainer{contentClass = 'panel-content__game-schedule', items = {{
		icon = IconWidget{iconName = 'mvp', color = 'bright-sun-0-text', size = '0.875rem'},
		title = 'MVP:',
		content = HtmlWidgets.Span{children = Array.extend(
			players,
			points and points > 1 and (' (' .. points .. ' pts)') or nil
		)},
	}}}
end

return MatchSummaryFfaMvp
