---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Draft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div, Fragment, Header = HtmlWidgets.Div, HtmlWidgets.Fragment, HtmlWidgets.Header
local MatchPageHeaderGameDraftCharacters = Lua.import('Module:Widget/Match/Page/Game/Draft/Characters')

---@class MatchPageHeaderGameDraft: Widget
---@operator call(table): MatchPageHeaderGameDraft
local MatchPageHeaderGameDraft = Class.new(Widget)

---@return Widget
function MatchPageHeaderGameDraft:render()
	return Fragment{children = {
		Header{level = 3, children = 'Draft'},
		Div{
			classes = {'match-bm-game-veto-wrapper'},
			children = {
				Div{
					classes = {'match-bm-lol-game-veto-overview-team'},
					children = {
						Div{
							classes = {'match-bm-game-veto-overview-team-header'},
							children = {self.props.opponents[1].icon},
						},
						Div{
							classes = {'match-bm-game-veto-overview-team-veto'},
							children = {
								MatchPageHeaderGameDraftCharacters{
									characters = self.props.opponents[1].picks,
									isBan = false,
									side = self.props.opponents[1].side,
								},
								MatchPageHeaderGameDraftCharacters{
									characters = self.props.opponents[1].bans,
									isBan = true,
								},
							},
						},
					},
				},
				Div{
					classes = {'match-bm-lol-game-veto-overview-team'},
					children = {
						Div{
							classes = {'match-bm-game-veto-overview-team-header'},
							children = {self.props.opponents[2].icon},
						},
						Div{
							classes = {'match-bm-game-veto-overview-team-veto'},
							children = {
								MatchPageHeaderGameDraftCharacters{
									characters = self.props.opponents[2].picks,
									isBan = false,
									side = self.props.opponents[2].side,
								},
								MatchPageHeaderGameDraftCharacters{
									characters = self.props.opponents[2].bans,
									isBan = true,
								},
							},
						},
					},
				}
			}
		}
	}}
end

return MatchPageHeaderGameDraft
