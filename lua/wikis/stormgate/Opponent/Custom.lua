---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local CustomOpponent = Table.deepCopy(Opponent)

CustomOpponent.types.Player = TypeUtil.extendStruct(Opponent.types.Player, {
	faction = 'string?',
})

CustomOpponent.types.PartyOpponent = TypeUtil.struct{
	players = TypeUtil.array(CustomOpponent.types.Player),
	type = TypeUtil.literalUnion(unpack(Opponent.partyTypes)),
}

CustomOpponent.types.Opponent = TypeUtil.union(
	Opponent.types.TeamOpponent,
	CustomOpponent.types.PartyOpponent,
	Opponent.types.LiteralOpponent
)

---@class StormgateStandardPlayer:standardPlayer
---@field faction string?

---@class StormgateStandardOpponent:standardOpponent
---@field players StormgateStandardPlayer[]
---@field isArchon boolean
---@field isSpecialArchon boolean?
---@field extradata table

---@param args table
---@return StormgateStandardOpponent?
function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as StormgateStandardOpponent?]]

	if not opponent then return nil end

	local partySize = Opponent.partySize(opponent.type)

	if partySize == 1 then
		opponent.players[1].faction = Faction.read(args.faction)
	elseif partySize then
		for playerIx, player in ipairs(opponent.players) do
			player.faction = Faction.read(args['p' .. playerIx .. 'faction'])
		end
	end

	return opponent
end

---@param record table
---@return StormgateStandardOpponent?
function CustomOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record) --[[@as StormgateStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.typeIsParty(opponent.type) then
		for playerIx, player in ipairs(opponent.players) do
			local playerRecord = record.match2players[playerIx]
			player.faction = Faction.read(playerRecord.extradata.faction) or Faction.defaultFaction
		end
	end

	return opponent
end

---@param opponent StormgateStandardOpponent
---@return table?
function CustomOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if Opponent.typeIsParty(opponent.type) then
		for playerIndex, player in pairs(opponent.players) do
			storageStruct.opponentplayers['p' .. playerIndex .. 'faction'] = player.faction
		end
	end

	return storageStruct
end

---@param storageStruct table
---@return StormgateStandardOpponent?
function CustomOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct) --[[@as StormgateStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.partySize(storageStruct.opponenttype) then
		for playerIndex, player in pairs(opponent.players) do
			player.faction = storageStruct.opponentplayers['p' .. playerIndex .. 'faction']
		end
	end

	return opponent
end

---@param opponent StormgateStandardOpponent
---@param date string|number|nil
---@param options {syncPlayer: boolean?, overwritePageVars: boolean?}
---@return StormgateStandardOpponent
function CustomOpponent.resolve(opponent, date, options)
	options = options or {}
	if Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local hasFaction = String.isNotEmpty(player.faction)
				local savePageVar = not Opponent.playerIsTbd(player)
				PlayerExt.syncPlayer(player, {
					date = date,
					savePageVar = savePageVar,
					overwritePageVars = options.overwritePageVars,
				})
				player.team = PlayerExt.syncTeam(
					player.pageName:gsub(' ', '_'),
					player.team,
					{
							date = date,
							savePageVar = savePageVar,
						}
				)
				player.faction = (hasFaction or player.faction ~= Faction.defaultFaction) and player.faction or nil
			else
				PlayerExt.populatePageName(player)
			end
			if player.team then
				player.team = TeamTemplate.resolve(player.team, date)
			end
		end

		return opponent
	end

	return Opponent.resolve(opponent, date, options) --[[@as StormgateStandardOpponent]]
end

return CustomOpponent
