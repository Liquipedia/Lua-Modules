---
-- @Liquipedia
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local CustomParticipantTable = {}

---@param frame Frame
---@return Html?
function CustomParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame)

	participantTable.displayEntry = CustomParticipantTable.displayEntry

	return participantTable:read():store():create()
end

---@param entry ParticipantTableEntry
---@param additionalProps table?
---@return Html
function CustomParticipantTable:displayEntry(entry, additionalProps)
	additionalProps = additionalProps or {}

	return mw.html.create('div')
		:addClass('participantTable-entry brkts-opponent-hover')
		:attr('aria-label', entry.name)
		:node(OpponentDisplay.BlockOpponent(Table.merge(additionalProps, {
			dq = entry.dq,
			note = entry.note,
			showPlayerTeam = self.config.showTeams,
			opponent = entry.opponent,
			oneLine = true,
		})))
end

return CustomParticipantTable
