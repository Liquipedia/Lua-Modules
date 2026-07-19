---
-- @Liquipedia
-- page=Module:Player/Display/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Characters = Lua.import('Module:Characters')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local BlockPlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Block/Character')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline/Character')
local PlayerDisplay = Lua.import('Module:Player/Display')

---@class CharacterPlayerDisplay: PlayerDisplay
local CustomPlayerDisplay = Table.copy(PlayerDisplay)

---@param props BlockCharacterPlayerDisplayProps
---@return Widget
function CustomPlayerDisplay.BlockPlayer(props)
	return BlockPlayerWidget(props)
end

---@param props InlineCharacterPlayerDisplayProps
---@return VNode
function CustomPlayerDisplay.InlinePlayer(props)
	return InlinePlayerWidget(props)
end

function CustomPlayerDisplay.character(game, character)
	return Characters.GetIconAndName{character, game = game}
end

---Called from Template:InlinePlayer
---@param props {[1]: string, flag: string?, link: string?, race: string?, faction: string?, date: string?,
---novar: string|boolean?, dq: string|boolean?, flip: string|boolean?, showFlag: string|boolean?,
---showLink: string|boolean?, showRace: string|boolean?, showFaction: string|boolean?, game: string?,
---chars: string?}
---@return VNode
function CustomPlayerDisplay.InlinePlayerByProps(props)
	props = Arguments.getArgs(props)
	-- temp alias for bot runs
	props.chars = props.chars or props.char

	local game = props.game or Variables.varDefault('tournament_game')
	local opponent = Opponent.readOpponentArgs(Table.merge(props, {game = game, type = Opponent.solo}))
	local player = opponent.players[1] --[[@as FightersStandardPlayer|SmashStandardPlayer]]

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
		game = game,
	}
end

return CustomPlayerDisplay
