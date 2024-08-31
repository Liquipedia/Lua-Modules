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

local Opponent = Lua.import('Module:Opponent')
local PlayerExt = Lua.import('Module:Player/Ext')
local StarcraftPlayerExt = Lua.import('Module:Player/Ext/Starcraft')

local StarcraftOpponent = Table.deepCopy(Opponent)

---@class StarcraftStandardPlayer:standardPlayer
---@field faction string?

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
		return nil
	end

	if partySize == 1 then
		opponent.players[1].faction = Faction.read(args.faction or args.race)

	elseif partySize then
		opponent.isArchon = Logic.readBool(args.isarchon)
		if opponent.isArchon then
			local archonFaction = Faction.read(args.faction or args.race)
			for _, player in ipairs(opponent.players) do
				player.faction = archonFaction
			end
		else
			for playerIx, player in ipairs(opponent.players) do
				player.faction = Faction.read(args['p' .. playerIx .. 'faction'] or args['p' .. playerIx .. 'race'])
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
			player.faction = Faction.read(playerRecord.extradata.faction) or Faction.defaultFaction
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
			storageStruct.opponentplayers.faction = opponent.players[1].faction
		else
			for playerIndex, player in pairs(opponent.players) do
				storageStruct.opponentplayers['p' .. playerIndex .. 'faction'] = player.faction
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
			player.faction = storageStruct.opponentplayers['p' .. playerIndex .. 'faction']
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
---@param options {syncPlayer: boolean?, overwritePageVars: boolean?}
---@return StarcraftStandardOpponent
function StarcraftOpponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		opponent.template = TeamTemplate.resolve(opponent.template, date) or opponent.template or 'tbd'
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local hasFaction = String.isNotEmpty(player.faction)
				local savePageVar = not Opponent.playerIsTbd(player --[[@as standardPlayer]])
				StarcraftPlayerExt.syncPlayer(player, {
					savePageVar = savePageVar,
					date = date,
					overwritePageVars = options.overwritePageVars,
				})
				player.team = PlayerExt.syncTeam(
					player.pageName:gsub(' ', '_'),
					player.team,
					{date = date, savePageVar = savePageVar}
				)
				player.faction = (hasFaction or player.faction ~= Faction.defaultFaction) and player.faction or nil
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
