---
-- @Liquipedia
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local TextSanitizer = require('Module:TextSanitizer')
local Variables = require('Module:Variables')

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local CustomParticipantTable = {}

---@param frame Frame
---@return Html?
function CustomParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame)

	participantTable.adjustLpdbData = CustomParticipantTable.adjustLpdbData

	return participantTable:read():store():create()
end

---@param lpdbData table
---@param entry ParticipantTableEntry
---@param config ParticipantTableConfig
function CustomParticipantTable:adjustLpdbData(lpdbData, entry, config)
	lpdbData.qualifier = TextSanitizer.stripHTML(config.title)
	lpdbData.extradata.status = Variables.varDefault('tournament_status', '')
end

return CustomParticipantTable
