---
-- @Liquipedia
-- wiki=commons
-- page=Module:ParticipantTable/Import
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local TournamentStructure = Lua.import('Module:TournamentStructure')

local ParticipantTableImport = {}

---@param config ParticipantTableConfig
---@param entriesByName table<string, ParticipantTableEntry>
---@return ParticipantTableEntry[]
function ParticipantTableImport.importFromMatchGroupSpec(config, entriesByName)
	if Table.isEmpty(config.matchGroupSpec) then
		return Array.extractValues(entriesByName)
	end

	local matchRecords = ParticipantTableImport._fetchMatchRecords(config.matchGroupSpec)
	if Table.isEmpty(matchRecords) then
		return Array.extractValues(entriesByName)
	end
	---@cast matchRecords -nil
	return ParticipantTableImport._entriesFromMatchRecords(matchRecords, config, entriesByName)
end

---@param matchGroupSpec table
---@return table[]
function ParticipantTableImport._fetchMatchRecords(matchGroupSpec)
	return mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = TournamentStructure.getMatch2Filter(matchGroupSpec),
		query = 'pagename, match2bracketdata, match2opponents, winner',
		order = 'date asc',
		limit = 5000,
	})
end

---@param matchRecords table[]
---@param config ParticipantTableConfig
---@param entriesByName table<string, ParticipantTableEntry>
---@return ParticipantTableEntry[]
function ParticipantTableImport._entriesFromMatchRecords(matchRecords, config, entriesByName)
	Array.forEach(matchRecords, function(matchRecord)
		Array.forEach(matchRecord.match2opponents, function(opponentRecord, opponentIndex)
			if not ParticipantTableImport._shouldInclude(opponentIndex, matchRecord, config.importOnlyQualified) then
				return
			end

			local entry = ParticipantTableImport._entryFromOpponentRecord(opponentRecord)
			if not entry then return end

			entriesByName[entry.name] = entriesByName[entry.name] or entry
		end)
	end)

	return Array.extractValues(entriesByName)
end

---@param opponentIndex integer
---@param matchRecord table
---@param importOnlyQualified boolean?
---@return boolean
function ParticipantTableImport._shouldInclude(opponentIndex, matchRecord, importOnlyQualified)
	local bracketData = matchRecord.match2bracketdata
	return not importOnlyQualified or Logic.readBool(bracketData.quallose) or
		Logic.readBool(bracketData.qualwin) and tonumber(matchRecord.winner) == opponentIndex
end

---@param opponentRecord table
---@return ParticipantTableEntry?
function ParticipantTableImport._entryFromOpponentRecord(opponentRecord)
	local opponent = Opponent.fromMatch2Record(opponentRecord) --[[@as standardOpponent]]
	if Opponent.isTbd(opponent) then
		return
	end
	return {
		opponent = opponent,
		name = opponentRecord.name,
	}
end

return ParticipantTableImport
