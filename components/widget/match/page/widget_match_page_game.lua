---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/Game
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Fragment = HtmlWidgets.Fragment
local MatchPageGameDraft = Lua.import('Module:Widget/Match/Page/Game/Draft')
local MatchPageGameStats = Lua.import('Module:Widget/Match/Page/Game/Stats')
local MatchPageGamePlayers = Lua.import('Module:Widget/Match/Page/Game/Players')

---@class MatchPageGame: Widget
---@operator call(table): MatchPageGame
local MatchPageGame = Class.new(Widget)

---@return Widget
function MatchPageGame:render()
	return Fragment{
		children = {
			MatchPageGameDraft{},
			MatchPageGameStats{},
			MatchPageGamePlayers{},
		}
	}
end

return MatchPageGame
