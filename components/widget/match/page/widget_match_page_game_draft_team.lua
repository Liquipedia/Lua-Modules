---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game/Draft/Team
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local MatchPageHeaderGameDraftCharacters = Lua.import('Module:Widget/Match/Page/Game/Draft/Characters')

---@class MatchPageHeaderGameDraftTeam: Widget
---@operator call(table): MatchPageHeaderGameDraftTeam
local MatchPageHeaderGameDraftTeam = Class.new(Widget)

---@return Widget
function MatchPageHeaderGameDraftTeam:render()
	local function getIconFromTeamTemplate(template)
		return template and mw.ext.TeamTemplate.teamicon(template) or nil
	end

	return Div{
		classes = {'match-bm-lol-game-veto-overview-team'},
		children = {
			Div{
				classes = {'match-bm-game-veto-overview-team-header'},
				children = getIconFromTeamTemplate{self.props.template},
			},
			Div{
				classes = {'match-bm-game-veto-overview-team-veto'},
				children = {
					MatchPageHeaderGameDraftCharacters{
						characters = self.props.picks,
						isBan = false,
						side = self.props.side,
					},
					MatchPageHeaderGameDraftCharacters{
						characters = self.props.bans,
						isBan = true,
					},
				},
			},
		},
	}
end

return MatchPageHeaderGameDraftTeam
