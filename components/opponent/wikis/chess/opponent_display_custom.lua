---
-- @Liquipedia
-- wiki=chess
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Opponent = Lua.import('Module:Opponent')

local CustomOpponent = Table.deepCopy(Opponent)

---@class ChessStandardPlayer:standardPlayer
---@field chars string[]?
---@field game string?

---@class ChessStandardOpponent:standardOpponent
---@field players ChessStandardPlayer[]

---@param args table
---@return ChessStandardOpponent?
function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as ChessStandardOpponent?]]

	if not opponent or not Opponent.typeIsParty(opponent.type) then return opponent end

	Array.forEach(opponent.players, function (player, playerIndex)
		player.rating = args['rating' .. playerIndex] or (playerIndex == 1 and args.rating) or nil
	end)

	return opponent
end

---@param opponent ChessStandardOpponent
---@return {opponentname: string, opponenttemplate: string?, opponenttype: OpponentType, opponentplayers: table?}
function CustomOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if not Opponent.typeIsParty(opponent.type) then
		return storageStruct
	end

	for playerIndex, player in pairs(opponent.players) do
		storageStruct.opponentplayers['p' .. playerIndex .. 'rating'] = player.rating
	end

	return storageStruct
end

---Reads a standings or placement lpdb structure and builds an opponent struct from it
---@param storageStruct table
---@return ChessStandardOpponent?
function CustomOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct) --[[@as ChessStandardOpponent?]]

	if not opponent or not Opponent.typeIsParty(opponent.type) then
		return opponent
	end

	for playerIndex, player in pairs(opponent.players) do
		player.rating = Logic.nilIfEmpty(storageStruct.opponentplayers['p' .. playerIndex .. 'rating'])
	end

	return opponent
end

return CustomOpponent
