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
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPageHeaderGameDraftCharacters: Widget
---@operator call(table): MatchPageHeaderGameDraftCharacters
local MatchPageHeaderGameDraftCharacters = Class.new(Widget)
MatchPageHeaderGameDraftCharacters.defaultProps = {
	isBan = false,
	side = '',
}

---@return Widget?
function MatchPageHeaderGameDraftCharacters:render()
	if not self.props.characters then
		return nil
	end
	local label = self.props.isBan and 'bans' or 'picks'
	local side = self.props.isBan and 'ban' or self.props.side

	return Div{
		classes = {'match-bm-game-veto-overview-team-veto-row', 'match-bm-game-veto-overview-team-veto-row--' .. side},
		attributes = {['aria-labelledby'] = label},
		children = Array.map(self.props.characters, function(character)
			return Div{
				classes = {'match-bm-game-veto-overview-team-veto-row-item'},
				children = {
					Div{
						classes = {'match-bm-game-veto-overview-team-veto-row-item-icon'},
						children = {character.heroIcon},
					},
					Div{
						classes = {'match-bm-game-veto-overview-team-veto-row-item-text'},
						children = {'#' .. character.vetoNumber},
					},
				},
			}
		end),
	}
end

return MatchPageHeaderGameDraftCharacters
