---
-- @Liquipedia
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Info = require('Module:Info')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Opponent = Lua.import('Module:Opponent')

local CustomOpponent = Table.deepCopy(Opponent)

---@class FightersStandardPlayer:standardPlayer
---@field chars string[]?
---@field game string?

---@class FightersStandardOpponent:standardOpponent
---@field players FightersStandardPlayer[]

---@param args table
---@return FightersStandardOpponent?
function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as FightersStandardOpponent?]]

	if not opponent or not Opponent.typeIsParty(opponent.type) then return opponent end

	local game = args.game or Variables.varDefault('tournament_game') or Info.defaultGame
	local CharacterStandardizationData = mw.loadData('Module:CharacterStandardization/' .. game)

	Array.forEach(opponent.players, function (player, playerIndex)
		player.game = game

		local stringInput = args['chars' .. playerIndex] or (playerIndex == 1 and args.chars) or nil
		local charInputs = Array.parseCommaSeparatedString(stringInput)
		player.chars = Array.map(charInputs, function(characterInput)
			if Logic.isEmpty(characterInput) then return nil end
			---@cast characterInput -nil
			return (assert(CharacterStandardizationData[characterInput:lower()], 'Invalid character:' .. characterInput))
		end)
	end)

	return opponent
end

---@param opponent FightersStandardOpponent
---@return {opponentname: string, opponenttemplate: string?, opponenttype: OpponentType, opponentplayers: table?}
function CustomOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if not Opponent.typeIsParty(opponent.type) then
		return storageStruct
	end

	for playerIndex, player in pairs(opponent.players) do
		storageStruct.opponentplayers['p' .. playerIndex .. 'chars'] = player.chars and table.concat(player.chars, ',') or nil
	end

	-- we do not have game in e.g. standingsentries, hence need to make it available in opponnetplayers
	storageStruct.opponentplayers.game = (opponent.players[1] or {}).game

	return storageStruct
end

---Reads a standings or placement lpdb structure and builds an opponent struct from it
---@param storageStruct table
---@return FightersStandardOpponent?
function CustomOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct) --[[@as FightersStandardOpponent?]]

	if not opponent or not Opponent.typeIsParty(opponent.type) then
		return opponent
	end

	for playerIndex, player in pairs(opponent.players) do
		player.game = storageStruct.game
			-- e.g. in standingsentries there is no game field
			or storageStruct.opponentplayers.game

		player.chars = Logic.nilIfEmpty(Array.parseCommaSeparatedString(
			storageStruct.opponentplayers['p' .. playerIndex .. 'chars']
		))
	end

	return opponent
end

return CustomOpponent
