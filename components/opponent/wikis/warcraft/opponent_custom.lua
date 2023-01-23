---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Race = require('Module:Race')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local PlayerExt = Lua.import('Module:Player/Ext/Custom', {requireDevIfEnabled = true})

local CustomOpponent = Table.deepCopy(Opponent)

CustomOpponent.types.Player = TypeUtil.extendStruct(Opponent.types.Player, {
	race = 'string?',
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

function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args)
	local partySize = Opponent.partySize((opponent or {}).type)

	if partySize == 1 then
		opponent.players[1].race = Race.read(args.race)
	elseif partySize then
		for playerIx, player in ipairs(opponent.players) do
			player.race = Race.read(args['p' .. playerIx .. 'race'])
		end
	end

	return opponent
end

function CustomOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record)

	if Opponent.typeIsParty(opponent.type) then
		for playerIx, player in ipairs(opponent.players) do
			local playerRecord = record.match2players[playerIx]
			player.race = Race.read(playerRecord.extradata.faction) or Race.defaultRace
		end
	end

	return opponent
end

function CustomOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if Opponent.typeIsParty(opponent.type) then
		for playerIndex, player in pairs(opponent.players) do
			storageStruct.opponentplayers['p' .. playerIndex .. 'faction'] = player.race
		end
	end

	return storageStruct
end

function CustomOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct)

	if Opponent.partySize(storageStruct.opponenttype) then
		for playerIndex, player in pairs(opponent.players) do
			player.race = storageStruct.opponentplayers['p' .. playerIndex .. 'faction']
		end
	end

	return opponent
end

function CustomOpponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		return Opponent.resolve(opponent, date, options)
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local hasRace = String.isNotEmpty(player.race)
				PlayerExt.syncPlayer(player, {savePageVar = not Opponent.playerIsTbd(player)})
				if not player.team then
					player.team = PlayerExt.syncTeam(player.pageName, nil, {date = date})
				end
				player.race = (hasRace or player.race ~= Race.defaultRace) and player.race or nil
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

return CustomOpponent
