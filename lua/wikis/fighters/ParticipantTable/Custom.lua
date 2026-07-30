---
-- @Liquipedia
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Table = Lua.import('Module:Table')

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local Entry = Lua.import('Module:Widget/Participants/Table/Entry')

---@class FightersParticipantTable: ParticipantTable
---@operator call(Frame): FightersParticipantTable
local CustomParticipantTable = Class.new(ParticipantTable)

---@param frame Frame
---@return Html?
function CustomParticipantTable.run(frame)
	return CustomParticipantTable(frame):read():store():create()
end

---@param entry ParticipantTableEntry
---@param additionalProps table?
---@return VNode
function CustomParticipantTable:displayEntry(entry, additionalProps)
	return Entry{
		config = self.config,
		dq = entry.dq,
		note = entry.note,
		opponent = entry.opponent,
		additionalProps = Table.mergeInto({oneLine = true}, additionalProps),
	}
end

return CustomParticipantTable
