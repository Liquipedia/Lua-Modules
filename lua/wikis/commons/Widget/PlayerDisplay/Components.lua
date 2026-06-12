---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Components
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')

local TeamPart = Lua.import('Module:Widget/TeamDisplay/Part')

local PlayerDisplayComponents = {}

PlayerDisplayComponents.defaultProps = {
	showFlag = true,
	showFaction = true,
}

---@param props {player: standardPlayer, showFlag: boolean?, useDefault: boolean?}
---@return string?
function PlayerDisplayComponents.flag(props)
	if not Logic.readBool(props.showFlag) then
		return
	end
	local flag = props.player.flag
	if Logic.isEmpty(flag) then
		if not props.useDefault then
			return
		end
		flag = 'unknown'
	end
	return Flags.Icon{flag = flag, shouldLink = false}
end

---@param props {player: standardPlayer, game: string?, showFaction: boolean?}
---@return string?
function PlayerDisplayComponents.faction(props)
	if not Logic.readBool(props.showFaction) then
		return
	end
	local player = props.player
	if Logic.isEmpty(player.faction) then
		return
	elseif player.faction == Faction.defaultFaction then
		return
	end
	return Faction.Icon{size = 'small', showLink = false, faction = player.faction, game = props.game}
end

---@param player standardPlayer
---@param showPlayerTeam boolean?
---@return Renderable[]?
function PlayerDisplayComponents.team(player, showPlayerTeam)
	local team = player.team

	if not Logic.readBool(showPlayerTeam) then
		return
	elseif Logic.isEmpty(team) then
		return
	end
	---@cast team -nil
	if team:lower() == 'tbd' then
		return
	end
	return {
		'&nbsp;',
		TeamPart{name = team}
	}
end

return PlayerDisplayComponents
