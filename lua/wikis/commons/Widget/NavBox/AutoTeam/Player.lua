---
-- @Liquipedia
-- page=Module:Widget/NavBox/AutoTeam/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Widget = Lua.import('Module:Widget')
local AutoTeamNavbox = Lua.import('Module:Widget/NavBox/AutoTeam')

---@class PlayerAutoTeamNavbox: Widget
---@operator call(table): PlayerAutoTeamNavbox
local PlayerAutoTeamNavbox = Class.new(Widget)
PlayerAutoTeamNavbox.defaultProps = {player = mw.title.getCurrentTitle().prefixedText}

---@return Widget?
function PlayerAutoTeamNavbox:render()
	local player = Page.pageifyLink(self.props.player)
	local queryResult = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'team',
		conditions = '[[pagename::' .. player .. ']]',
		limit = 1,
	})[1] or {}
	local team = queryResult.team
	if Logic.isEmpty(team) then return end

	return AutoTeamNavbox{team = team}
end

return PlayerAutoTeamNavbox
