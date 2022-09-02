---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:PrizePool/Import/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Import = Lua.import('Module:PrizePool/Import', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})
local TournamentUtil = Lua.import('Module:Tournament/Util', {requireDevIfEnabled = true})

local CustomImport = {}

local IMPORT_DEFAULT_ENABLE_START = '2022-01-14'

function CustomImport.run(placements, args)
	args.importLimit = tonumber(args.importLimit) or CustomImport._computeDefaultImportLimit()
	args.import = CustomImport._computeImportEnable(args.import)

	-- call the commons import + populate player Teams where necessary
	return CustomImport._populatePlayerTeams(Import.run(placements, args))
end

function CustomImport._computeDefaultImportLimit()
	local tier = tonumber(Variables.varDefault('tournament_liquipediatier'))
	if not tier then
		mw.log('Prize Pool Import: Unset liquipediatier')
		return
	end

	return tier >= 4 and 8
		or tier == 3 and 16
		or nil
end

function CustomImport._computeImportEnable(importInput)
	local tournamentEndDate = TournamentUtil.getContextualDate()
	return Logic.nilOr(
		Logic.readBoolOrNil(importInput),
		not tournamentEndDate or tournamentEndDate >= IMPORT_DEFAULT_ENABLE_START
	)
end

function CustomImport._populatePlayerTeams(placements)
	for _, placement in pairs(placements) do
		for _, opponent in pairs(placement.opponents) do
			opponent.opponentData = CustomImport._completeOpponentPlayerTeams(
				opponent.opponentData,
				opponent.date or placement.date
			)
		end
	end

	return placements
end

function CustomImport._completeOpponentPlayerTeams(opponent, date)
	if not Opponent.typeIsParty(opponent.type) then
		return opponent
	end

	for _, player in pairs(opponent.players) do
		if not player.team and player.displayName and player.pageName and not Opponent.playerIsTbd(player) then
			player.team = PlayerExt.syncTeam(player.pageName, nil, {date = date})
		end
	end

	return opponent
end

return CustomImport
