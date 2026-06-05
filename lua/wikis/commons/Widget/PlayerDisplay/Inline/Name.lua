---
-- @Liquipedia
-- page=Module:Widget/PlayerDisplay/Inline/Name
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

---@param props {player: standardPlayer, showLink: boolean?, dq: boolean?}
---@return Renderable?
local function InlinePlayerName(props)
	local player = props.player
	local showLink = Logic.readBool(props.showLink)
	local name = (showLink and Logic.isNotEmpty(player.pageName)) and Link{
		link = player.pageName, children = player.displayName
	} or player.displayName
	if props.dq then
		return Html.S{children = name}
	end
	return name
end

return Component.component(InlinePlayerName, {showLink = true})
