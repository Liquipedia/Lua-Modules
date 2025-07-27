---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PlayerDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPagePlayerDisplayParameters
---@field characterIcon (string|Html|Widget|nil)
---@field characterName string
---@field side string
---@field roleIcon (string|Html|Widget|nil)
---@field playerName string
---@field playerLink string?

---@class MatchPagePlayerDisplay: Widget
---@operator call(MatchPagePlayerDisplayParameters): MatchPagePlayerDisplay
---@field props MatchPagePlayerDisplayParameters
local MatchPagePlayerDisplay = Class.new(Widget)

---@return Widget
function MatchPagePlayerDisplay:render()
	return Div{
		classes = {'match-bm-players-player-character'},
		children = {
			Div{
				classes = {'match-bm-players-player-avatar'},
				children = {
					Div{
						classes = {'match-bm-players-player-icon'},
						children = self.props.characterIcon
					},
					Div{
						classes = {
							'match-bm-players-player-role',
							self.props.side and 'role--' .. self.props.side  or nil
						},
						children = self.props.roleIcon
					}
				}
			},
			Div{
				classes = {'match-bm-players-player-name'},
				children = {
					Link{
						link = self.props.playerLink or self.props.playerName,
						children = self.props.playerName
					},
					HtmlWidgets.I{children = self.props.characterName}
				}
			}
		}
	}
end

return MatchPagePlayerDisplay
