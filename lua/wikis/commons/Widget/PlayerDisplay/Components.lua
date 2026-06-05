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

local Component = Lua.import('Module:Widget/Component')

local PlayerDisplayComponents = {}

PlayerDisplayComponents.flag = Component.component(
	---@param props {player: standardPlayer, showFlag: boolean?, useDefault: boolean?}
	---@return string?
	function (props)
		if not props.showFlag then
			return
		end
		local flag = props.player.flag
		if Logic.isEmpty(flag) and props.useDefault then
			flag = 'unknown'
		end
		return Flags.Icon{flag = flag, shouldLink = false}
	end
)

PlayerDisplayComponents.faction = Component.component(
	---@param props {player: standardPlayer, game: string?, showFaction: boolean?}
	---@return string?
	function (props)
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
	end,
	{showFaction = true}
)

return PlayerDisplayComponents
