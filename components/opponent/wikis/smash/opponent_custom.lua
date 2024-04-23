---
-- @Liquipedia
-- wiki=smash
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Info = require('Module:Info')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Opponent = Lua.import('Module:Opponent')

local CustomOpponent = Table.deepCopy(Opponent)

---@class SmashStandardPlayer:standardPlayer
---@field chars string[]?
---@field game string?

---@class SmashStandardOpponent:standardOpponent
---@field players SmashStandardPlayer[]

---@param args table
---@return SmashStandardOpponent?
function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as SmashStandardOpponent?]]

	if not opponent then return nil end

	local partySize = Opponent.partySize(opponent.type)

	if partySize == 1 then
		opponent.players[1].chars = Array.parseCommaSeparatedString(args.chars)
		opponent.players[1].game = args.game or Variables.varDefault('tournament_game') or Info.defaultGame
	elseif partySize then
		Array.forEach(opponent.players, function (player)
			player.chars = Array.parseCommaSeparatedString(args.chars)
		end)
	end

	return opponent
end

return CustomOpponent
