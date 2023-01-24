---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchGroup/Util/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local CustomMatchGroupUtil = Table.deepCopy(MatchGroupUtil)

CustomMatchGroupUtil.types.Race = TypeUtil.literalUnion(unpack(Faction.factions))

CustomMatchGroupUtil.types.Player = TypeUtil.extendStruct(MatchGroupUtil.types.Player, {
	position = 'number?',
	race = CustomMatchGroupUtil.types.Race,
})

CustomMatchGroupUtil.types.GameOpponent = TypeUtil.struct({
	placement = 'number?',
	players = TypeUtil.array(CustomMatchGroupUtil.types.Player),
	score = 'number?',
})

return CustomMatchGroupUtil
