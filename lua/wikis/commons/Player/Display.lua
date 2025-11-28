---
-- @Liquipedia
-- page=Module:Player/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')

local BlockPlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Block')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline')

local TBD = 'TBD'
local ZERO_WIDTH_SPACE = '&#8203;'

--Display components for players.
---@class PlayerDisplay
local PlayerDisplay = {}

--Displays a player as a block element. The width of the component is
--determined by its layout context, and not by the player name.
---@param props BlockPlayerProps
---@return Widget
function PlayerDisplay.BlockPlayer(props)
	return BlockPlayerWidget(props)
end

---Displays a player as an inline element. Useful for referencing players in prose.
---@param props BasePlayerDisplayProps
---@return Widget
function PlayerDisplay.InlinePlayer(props)
	return InlinePlayerWidget(props)
end

-- Note: Lua.import('Module:Flags').Icon automatically includes a span with class="flag"
---@param props {flag: string?, useDefault: boolean}
---@return string
function PlayerDisplay.Flag(props)
	local flag = props.flag
	if not flag and props.useDefault then
		flag = 'unknown'
	end
	return Flags.Icon{flag = flag, shouldLink = false}
end

return Class.export(PlayerDisplay, {exports = {
	'BlockPlayer',
	'InlinePlayer',
	'Flag',
}})
