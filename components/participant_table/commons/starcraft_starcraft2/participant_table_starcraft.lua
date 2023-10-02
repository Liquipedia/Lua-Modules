---
-- @Liquipedia
-- wiki=commons
-- page=Module:ParticipantTable/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Variables = require('Module:Variables')

---@class StarcraftParticipantTableConfig: ParticipantTableConfig
---@field displayUnknownColumn boolean?
---@field displayRandomColumn boolean?
---@field showCountByRace boolean
---@field isRandomEvent boolean
---@field isQualified boolean?

---@class StarcraftParticipantTableEntry: ParticipantTableEntry
---@field isQualified boolean?
---@field opponent StarcraftStandardOpponent

---@class StarcraftParticipantTable: ParticipantTable
---@field isPureSolo boolean
local ParticipantTable = Lua.import('Module:ParticipantTable/Starcraft', {requireDevIfEnabled = true})

local OpponentLibraries = require('OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local prizePoolVars = PageVariableNamespace('PrizePool')

local ROLL_OUT_DATE = '2023-10-31'

local StarcraftParticipantTable = {}

---@param frame Frame
---@return Html
function StarcraftParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame)

	participantTable.args.noStorage = participantTable.args.noStorage or
		Variables.varDefault('tournament_startdate') > ROLL_OUT_DATE

	participantTable.readConfig = StarcraftParticipantTable.readConfig
	participantTable.readEntry = StarcraftParticipantTable.readEntry
	participantTable.buildExtradata = StarcraftParticipantTable.buildExtradata
	participantTable.getPlacements = StarcraftParticipantTable.getPlacements

	participantTable:init():store()

	if StarcraftParticipantTable.isPureSolo(participantTable.sections) then
		participantTable.create = StarcraftParticipantTable.createSoloRaceTable
	end

	return participantTable:create()
end

---@param args table
---@param parentConfig StarcraftParticipantTableConfig?
---@return StarcraftParticipantTableConfig
function StarcraftParticipantTable.readConfig(args, parentConfig)
	local config = ParticipantTable.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}

	config.displayUnknownColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.displayRandomColumn = Logic.readBoolOrNil(args.unknowncolumn)
	config.showCountByRace = Logic.readBool(args.showCountByRace or args.count)
	config.isRandomEvent = Logic.readBool(args.is_random_event)
	config.isQualified = Logic.nilOr(Logic.readBoolOrNil(args.isQualified), parentConfig.isQualified)
	config.sortOpponents = Logic.nilOr(Logic.readBoolOrNil(args.sortOpponents or parentConfig.sortOpponents), true)
	config.sortPlayers = true

	return config
end

---@param sectionArgs table
---@param key string|number
---@param config any
---@return StarcraftParticipantTableEntry
function StarcraftParticipantTable:readEntry(sectionArgs, key, config)
	--if not a json assume it is a solo opponent
	local opponentArgs = Json.parseIfTable(sectionArgs[key]) or Logic.isNumeric(key) and {
		type = Opponent.solo,
		name = sectionArgs[key],
	} or {
		type = Opponent.solo,
		name = sectionArgs[key],
		link = sectionArgs[key .. 'link'],
		flag = sectionArgs[key .. 'flag'],
		team = sectionArgs[key .. 'team'],
		race = sectionArgs[key .. 'race'],
	}

	assert(Opponent.isType(opponentArgs.type) and opponentArgs.type ~= Opponent.team,
		'Missing or unsupported opponent type for "' .. sectionArgs[key] .. '"')

	local opponent = Opponent.readOpponentArgs(opponentArgs)

	if config.sortPlayers and opponent.players then
		table.sort(opponent.players, function (player1, player2)
			local name1 = (player1.displayName or player1.name):lower()
			local name2 = (player2.displayName or player2.name):lower()
			return name1 < name2
		end)
	end

	return {
		opponent = opponent,
		name = Opponent.toName(opponent),
		isQualified = Logic.nilOr(Logic.readBoolOrNil(sectionArgs[key .. 'qualified']) or config.isQualified),
	}
end

---@param lpdbData table
---@param entry table
---@return table
function StarcraftParticipantTable:buildExtradata(lpdbData, entry)
	local seriesNumber = tonumber(Variables.varDefault('tournament_series_number'))
	return {
		seriesnumber = seriesNumber and string.format('%05d', seriesNumber) or nil,
		isQualified = tostring(entry.isQualified),
	}

end

---@return table<string, true>
function StarcraftParticipantTable:getPlacements()
	local placements = {}
	local maxPrizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0

	for prizePoolIndex = 1, maxPrizePoolIndex do
		Array.forEach(Json.parseIfTable(prizePoolVars:get('placementRecords.' .. prizePoolIndex)) or {}, function(placement)
			placements[placement.opponentname] = true
		end)
	end

	return placements
end

function StarcraftParticipantTable.isPureSolo(sections)
	return Array.all(sections, function(section) return Array.all(section.entries, function(entry)
		return entry.opponent.type == Opponent.solo
	end) end)
end

---@return Html
function StarcraftParticipantTable:createSoloRaceTable()
	someBS
	return Html ---todo
end

return StarcraftParticipantTable
