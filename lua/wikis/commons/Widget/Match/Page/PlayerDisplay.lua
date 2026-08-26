---
-- @Liquipedia
-- page=Module:Widget/Match/Page/PlayerDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPagePlayerDisplayParameters
---@field characterIcon Renderable?
---@field characterName string
---@field side string?
---@field roleIcon Renderable?
---@field playerName string
---@field playerLink string?

---@param props MatchPagePlayerDisplayParameters
---@return VNode
local function MatchPagePlayerDisplay(props)
	return Div{
		classes = {'match-bm-players-player-character'},
		children = {
			Div{
				classes = {'match-bm-players-player-avatar'},
				children = {
					Div{
						classes = {'match-bm-players-player-icon'},
						children = props.characterIcon
					},
					Div{
						classes = {
							'match-bm-players-player-role',
							props.side and 'role--' .. props.side or nil
						},
						children = props.roleIcon
					}
				}
			},
			Div{
				classes = {'match-bm-players-player-name'},
				children = {
					Link{
						link = props.playerLink or props.playerName,
						children = props.playerName
					},
					Html.I{children = props.characterName}
				}
			}
		}
	}
end

return Component.component(MatchPagePlayerDisplay)
