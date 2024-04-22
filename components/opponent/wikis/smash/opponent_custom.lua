---
-- @Liquipedia
-- wiki=smash
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

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
		opponent.players[1].chars = args.chars and mw.text.split(args.chars or '', ',') or nil
		opponent.players[1].game = args.game
	elseif partySize then
		for _, player in ipairs(opponent.players) do
			player.chars = args.chars and mw.text.split(args.chars or '', ',') or nil
		end
	end

	return opponent
end

return CustomOpponent
