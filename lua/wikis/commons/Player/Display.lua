---
-- @Liquipedia
-- page=Module:Player/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local BlockPlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Block')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline')

--Display components for players.
---@class PlayerDisplay
local PlayerDisplay = {}

--Displays a player as a block element. The width of the component is
--determined by its layout context, and not by the player name.
---@param props BlockPlayerDisplayProps
---@return VNode
function PlayerDisplay.BlockPlayer(props)
	return BlockPlayerWidget(props)
end

---Displays a player as an inline element. Useful for referencing players in prose.
---@param props InlinePlayerDisplayProps
---@return VNode
function PlayerDisplay.InlinePlayer(props)
	return InlinePlayerWidget(props)
end

---Called from Template:InlinePlayer
---@param props {[1]: string, flag: string?, link: string?, race: string?, faction: string?, date: string?,
---novar: string|boolean?, dq: string|boolean?, flip: string|boolean?, showFlag: string|boolean?,
---showLink: string|boolean?, showRace: string|boolean?, showFaction: string|boolean?, game: string?}
---@return VNode
function PlayerDisplay.InlinePlayerByProps(props)
	local player = Opponent.readSinglePlayerArgs(props)

	PlayerExt.syncPlayer(player, {
		date = props.date,
		savePageVar = not Logic.readBool(props.novar),
		overwritePageVars = true,
	})

	return InlinePlayerWidget{
		date = props.date,
		dq = Logic.readBoolOrNil(props.dq),
		flip = Logic.readBoolOrNil(props.flip),
		player = player,
		savePageVar = not Logic.readBool(props.novar),
		showFlag = Logic.readBoolOrNil(props.showFlag),
		showLink = Logic.readBoolOrNil(props.showLink),
		showFaction = Logic.nilOr(Logic.readBoolOrNil(props.showRace), Logic.readBoolOrNil(props.showFaction)),
		-- needed for aoe faction lookups
		game = props.game and Game.abbreviation{game = props.game}:lower() or nil,
	}
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
	'InlinePlayerByProps',
}})
