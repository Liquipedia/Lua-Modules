---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Lib/ParseImported
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Set = Lua.import('Module:Set')

local Parser = {}

---@param config ParticipantTableConfig
---@param entries ParticipantTableEntry[]
---@param matchRecords match2[]
---@return ParticipantTableEntry[]
function Parser.parseImported(config, entries, matchRecords)
	if Logic.isEmpty(matchRecords) then
		return {}
	end
	---@type Set<string>
	local alreadyProcessed = Set(Array.map(entries, Operator.property('name')))
	---@cast matchRecords -nil

	local newEntries = {}
	Array.forEach(matchRecords, function(matchRecord)
		Array.forEach(matchRecord.match2opponents, function(opponentRecord, opponentIndex)
			if not Parser._shouldInclude(opponentIndex, matchRecord, config.importOnlyQualified) then
				return
			end

			local entry = Parser._entryFromOpponentRecord(opponentRecord)
			if not entry or alreadyProcessed:contains(entry.name) then return end

			alreadyProcessed:add(entry.name)

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
	local opponent = Opponent.fromMatch2Record(opponentRecord)
	if Opponent.isTbd(opponent) then
		return
	end
	return {
		opponent = opponent,
		name = opponentRecord.name,
	}
end

return Parser
