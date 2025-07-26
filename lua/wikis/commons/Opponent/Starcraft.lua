---
-- @Liquipedia
-- page=Module:Opponent/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Opponent = Lua.import('Module:Opponent')

local StarcraftOpponent = Table.deepCopy(Opponent)

---@class StarcraftStandardPlayer:standardPlayer
---@field position integer?

---@class StarcraftStandardOpponent:standardOpponent
---@field players StarcraftStandardPlayer[]
---@field isArchon boolean
---@field isSpecialArchon boolean?
---@field extradata table

---@param args table
---@return StarcraftStandardOpponent?
function StarcraftOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as StarcraftStandardOpponent?]]
	local partySize = Opponent.partySize((opponent or {}).type)

	if not opponent then
		return opponent
	end

	opponent.isArchon = partySize and Logic.readBool(args.isarchon) or false
	if not opponent.isArchon then
		return opponent
	end

	local archonFaction = Faction.read(args.faction or args.race)
	for _, player in ipairs(opponent.players) do
		player.faction = archonFaction
	end

	return opponent
end

---@param type OpponentType?
---@return StarcraftStandardOpponent
function StarcraftOpponent.blank(type)
	local opponent = Opponent.blank(type) --[[@as StarcraftStandardOpponent]]
	opponent.isArchon = false

	return opponent
end

---@param type OpponentType?
---@return StarcraftStandardOpponent
function StarcraftOpponent.tbd(type)
	local opponent = Opponent.tbd(type) --[[@as StarcraftStandardOpponent]]
	opponent.isArchon = false

	return opponent
end

---@param record table
---@return StarcraftStandardOpponent?
function StarcraftOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record) --[[@as StarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	opponent.isArchon = Logic.readBool((record.extradata or {}).isarchon)

	return opponent
end

---@param opponent StarcraftStandardOpponent
---@return table?
function StarcraftOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if Opponent.typeIsParty(opponent.type) and opponent.isArchon then
		storageStruct.opponentplayers.isArchon = true
		storageStruct.opponentplayers.faction = opponent.players[1].faction
	end

	return storageStruct
end

---@param storageStruct table
---@return StarcraftStandardOpponent?
function StarcraftOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct) --[[@as StarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	opponent.isArchon = storageStruct.opponentplayers.isArchon

	return opponent
end

return StarcraftOpponent
