---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CivLookup = require('Module:CivLookup')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent')

local CustomOpponent = Table.deepCopy(Opponent)

CustomOpponent.types.Player = TypeUtil.extendStruct(Opponent.types.Player, {
	civ = 'string?'
})

CustomOpponent.types.PartyOpponent = TypeUtil.struct{
	players = TypeUtil.array(CustomOpponent.types.Player),
	type = TypeUtil.literalUnion(unpack(Opponent.partyTypes))
}

CustomOpponent.types.Opponent = TypeUtil.union(
	Opponent.types.TeamOpponent,
	CustomOpponent.types.PartyOpponent,
	Opponent.types.LiteralOpponent
)

function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args)
	local partySize = Opponent.partySize((opponent or {}).type)

	if partySize == 1 then
		opponent.players[1].civ = CivLookup._getName(args)
	elseif partySize then
		for index, player in ipairs(opponent.players) do
			player.civ = args['p' .. index .. 'civ']
				and CivLookup._getName{civ = args['p' .. index .. 'civ']} or nil
		end
	end

	return opponent
end

return CustomOpponent
