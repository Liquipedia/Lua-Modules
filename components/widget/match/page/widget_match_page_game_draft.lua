---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Draft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Fragment, Header = HtmlWidgets.Div, HtmlWidgets.Fragment, HtmlWidgets.Header
local MatchPageHeaderGameDraftTeam = Lua.import('Module:Widget/Match/Page/Game/Draft/Team')

---@class MatchPageHeaderGameDraft: Widget
---@operator call(table): MatchPageHeaderGameDraft
local MatchPageHeaderGameDraft = Class.new(Widget)

---@return Widget
function MatchPageHeaderGameDraft:render()
	return Fragment{children = {
		Header{level = 3, children = 'Draft'},
		Div{
			classes = {'match-bm-game-veto-wrapper'},
			children = Array.map(self.props.opponents, function(opponent)
				return MatchPageHeaderGameDraftTeam{
					icon = opponent.icon,
					picks = opponent.picks,
					bans = opponent.bans,
					side =opponent.side,
				}
			end)
		}
	}}
end

return MatchPageHeaderGameDraft
