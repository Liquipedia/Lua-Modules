---
-- @Liquipedia
-- wiki=commons
-- page=Module:Opponent/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Opponent = require('Module:Opponent')
local StarcraftRace = require('Module:Race/Starcraft')
local StarcraftPlayerExt = require('Module:Player/Ext/Starcraft')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

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

--[[
Not supported:

Legacy TeamOpponent ({{TeamOpponent|players=...}})
TeamOpponent without team template ({{TeamOpponent|name=...|short=...}})
]]
function StarcraftOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args)
	local partySize = Opponent.partySize(opponent.type)

	if partySize == 1 then
		opponent.players[1].race = StarcraftRace.read(args.race)

	elseif partySize then
		opponent.isArchon = Logic.readBool(args.isarchon)
		if opponent.isArchon then
			local archonRace = StarcraftRace.read(args.race)
			for _, player in ipairs(opponent.players) do
				player.race = archonRace
			end
		else
			for playerIx, player in ipairs(opponent.players) do
				player.race = StarcraftRace.read(args['p' .. playerIx .. 'race'])
			end
		end
	end

	return opponent
end

function StarcraftOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record)

	if Opponent.typeIsParty(opponent.type) then
		for playerIx, player in ipairs(opponent.players) do
			local playerRecord = record.match2players[playerIx]
			player.race = StarcraftRace.read(playerRecord.extradata.faction) or 'u'
		end
		opponent.isArchon = Logic.readBool((record.extradata or {}).isarchon)
	end

	return opponent
end

function StarcraftOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent, true)

	if Opponent.typeIsParty(opponent.type) then
		if opponent.isArchon then
			storageStruct.players.isArchon = true
			storageStruct.players.faction = opponent.players[1].race
		else
			for playerIndex, player in pairs(opponent.players) do
				storageStruct.players['p' .. playerIndex .. 'faction'] = player.race
			end
		end
	end

	return storageStruct
end

function StarcraftOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct)

	if Opponent.partySize(storageStruct.opponenttype) then
		opponent.isArchon = storageStruct.players.isArchon
		for playerIndex, player in pairs(opponent.players) do
			player.race = storageStruct['p' .. playerIndex .. 'faction']
				or storageStruct.faction
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
function StarcraftOpponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		opponent.template = TeamTemplate.resolve(opponent.template, date) or 'tbd'
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				StarcraftPlayerExt.syncPlayer(player)
			else
				StarcraftPlayerExt.populatePageName(player)
			end
			if player.team then
				player.team = TeamTemplate.resolve(player.team, date)
			end
		end
	end
	return opponent
end

return StarcraftOpponent
