---
-- @Liquipedia
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local TextSanitizer = Lua.import('Module:TextSanitizer')
local Variables = Lua.import('Module:Variables')

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

---@class CounterstrikeParticipantTable: ParticipantTable
---@operator call(Frame): CounterstrikeParticipantTable
local CustomParticipantTable = Class.new(ParticipantTable)

---@param frame Frame
---@return Html?
function CustomParticipantTable.run(frame)
	return CustomParticipantTable(frame):read():store():create()
end

---@param lpdbData table
---@param entry ParticipantTableEntry
---@param config ParticipantTableConfig
function CustomParticipantTable:adjustLpdbData(lpdbData, entry, config)
	lpdbData.qualifier = TextSanitizer.stripHTML(config.title)
	lpdbData.extradata.status = Variables.varDefault('tournament_status', '')
end

return CustomParticipantTable
