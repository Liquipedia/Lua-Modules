---
-- @Liquipedia
-- wiki=commons
-- page=Module:Opponent/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})
local StarcraftPlayerExt = Lua.import('Module:Player/Ext/Starcraft', {requireDevIfEnabled = true})

local StarcraftOpponent = Table.deepCopy(Opponent)

StarcraftOpponent.types.Player = TypeUtil.extendStruct(Opponent.types.Player, {
	race = 'string?',
})

StarcraftOpponent.types.PartyOpponent = TypeUtil.struct{
	isArchon = 'boolean',
	isSpecialArchon = 'boolean?',
	players = TypeUtil.array(StarcraftOpponent.types.Player),
	type = TypeUtil.literalUnion(unpack(Opponent.partyTypes)),
}

StarcraftOpponent.types.Opponent = TypeUtil.union(
	Opponent.types.TeamOpponent,
	StarcraftOpponent.types.PartyOpponent,
	Opponent.types.LiteralOpponent
)

---@class StarcraftStandardPlayer:standardPlayer
---@field race string?

---@class StarcraftStandardOpponent:standardOpponent
---@field players StarcraftStandardPlayer[]
---@field isArchon boolean
---@field isSpecialArchon boolean?
---@field extradata table

--[[
Not supported:

Legacy TeamOpponent ({{TeamOpponent|players=...}})
TeamOpponent without team template ({{TeamOpponent|name=...|short=...}})
]]
---@param args table
---@return StarcraftStandardOpponent?
function StarcraftOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as StarcraftStandardOpponent?]]
	local partySize = Opponent.partySize((opponent or {}).type)

	if not opponent then
		return nil
	end

	if partySize == 1 then
		opponent.players[1].race = Faction.read(args.race)

	elseif partySize then
		opponent.isArchon = Logic.readBool(args.isarchon)
		if opponent.isArchon then
			local archonRace = Faction.read(args.race)
			for _, player in ipairs(opponent.players) do
				player.race = archonRace
			end
		else
			for playerIx, player in ipairs(opponent.players) do
				player.race = Faction.read(args['p' .. playerIx .. 'race'])
			end
		end
	end

	return opponent
end

---@param record table
---@return StarcraftStandardOpponent?
function StarcraftOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record) --[[@as StarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.typeIsParty(opponent.type) then
		for playerIx, player in ipairs(opponent.players) do
			local playerRecord = record.match2players[playerIx]
			player.race = Faction.read(playerRecord.extradata.faction) or Faction.defaultFaction
		end
		opponent.isArchon = Logic.readBool((record.extradata or {}).isarchon)
	end

	return opponent
end

---@param opponent StarcraftStandardOpponent
---@return table?
function StarcraftOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if Opponent.typeIsParty(opponent.type) then
		if opponent.isArchon then
			storageStruct.opponentplayers.isArchon = true
			storageStruct.opponentplayers.faction = opponent.players[1].race
		else
			for playerIndex, player in pairs(opponent.players) do
				storageStruct.opponentplayers['p' .. playerIndex .. 'faction'] = player.race
			end
		end
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

	if Opponent.partySize(storageStruct.opponenttype) then
		opponent.isArchon = storageStruct.opponentplayers.isArchon
		for playerIndex, player in pairs(opponent.players) do
			player.race = storageStruct.opponentplayers['p' .. playerIndex .. 'faction']
				or storageStruct.opponentplayers.faction
		end
	end

	return opponent
end

--[[
Resolves the identifiers of an opponent.
For team opponents, this resolves the team template to a particular date. For
party opponents, this fills in players' pageNames using their displayNames,
using data stored in page variables if present.
options.syncPlayer: Whether to fetch player information from variables or LPDB. Disabled by default.
]]
---@param opponent StarcraftStandardOpponent
---@param date string|number|osdate|nil
---@param options {syncPlayer: boolean?}
---@return StarcraftStandardOpponent
function StarcraftOpponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		opponent.template = TeamTemplate.resolve(opponent.template, date) or opponent.template or 'tbd'
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local hasRace = String.isNotEmpty(player.race)
				local savePageVar = not Opponent.playerIsTbd(player --[[@as standardPlayer]])
				StarcraftPlayerExt.syncPlayer(player, {savePageVar = savePageVar})
				player.team = PlayerExt.syncTeam(player.pageName:gsub(' ', '_'), player.team, {date = date, savePageVar = savePageVar})
				player.race = (hasRace or player.race ~= Faction.defaultFaction) and player.race or nil
			else
				PlayerExt.populatePageName(player)
			end
			if player.team then
				player.team = TeamTemplate.resolve(player.team, date)
			end
		end
	end
	return opponent
end

return StarcraftOpponent
