---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Lib/ParseImported
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local Parser = {}

---@param config ParticipantTableConfig
---@param entries ParticipantTableEntry[]
---@param matchRecords match2[]
---@return ParticipantTableEntry[]
function Parser.parseImported(config, entries, matchRecords)
	if Logic.isEmpty(matchRecords) then
		return {}
	end
	---@type table<string, true>
	local alreadyProcessed = Table.map(entries, function(key, entry)
		return entry.name, true
	end)
	---@cast matchRecords -nil

	local newEntries = {}
	Array.forEach(matchRecords, function(matchRecord)
		Array.forEach(matchRecord.match2opponents, function(opponentRecord, opponentIndex)
			if not Parser._shouldInclude(opponentIndex, matchRecord, config.importOnlyQualified) then
				return
			end

			local entry = Parser._entryFromOpponentRecord(opponentRecord)
			if not entry or alreadyProcessed[entry.name] then return end

			alreadyProcessed[entry.name] = true

			table.insert(newEntries, entry)
		end)
	end)

	return newEntries
end

---@param opponentIndex integer
---@param matchRecord table
---@param importOnlyQualified boolean?
---@return boolean
function Parser._shouldInclude(opponentIndex, matchRecord, importOnlyQualified)
	local bracketData = matchRecord.match2bracketdata
	return not importOnlyQualified or Logic.readBool(bracketData.quallose) or
		Logic.readBool(bracketData.qualwin) and tonumber(matchRecord.winner) == opponentIndex
end

---@param opponentRecord table
---@return ParticipantTableEntry?
function Parser._entryFromOpponentRecord(opponentRecord)
	local opponent = Opponent.fromMatch2Record(opponentRecord) --[[@as standardOpponent]]
	if Opponent.isTbd(opponent) then
		return
	end
	return {
		opponent = opponent,
		name = opponentRecord.name,
	}
end

return Parser