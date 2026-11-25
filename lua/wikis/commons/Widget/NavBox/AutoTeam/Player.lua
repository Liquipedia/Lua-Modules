---
-- @Liquipedia
-- page=Module:Widget/NavBox/AutoTeam/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Component = Lua.import('Module:Widget/Component')
local AutoTeamNavbox = Lua.import('Module:Widget/NavBox/AutoTeam')

local defaultProps = {player = mw.title.getCurrentTitle().prefixedText}

---@param props {player: string?}
---@return Renderable?
local function PlayerAutoTeamNavbox(props)
	local player = Page.pageifyLink(props.player)
	local queryResult = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'team',
		conditions = '[[pagename::' .. player .. ']]',
		limit = 1,
	})[1] or {}
	local team = queryResult.team
	if Logic.isEmpty(team) then
		return
	end

	return AutoTeamNavbox{team = team}
end

return Component.component(PlayerAutoTeamNavbox, defaultProps)
