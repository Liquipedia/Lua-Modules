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

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

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
---@return Html
function CustomParticipantTable:displayEntry(entry, additionalProps)
	additionalProps = additionalProps or {}

	local entryNode = mw.html.create('div')
		:addClass('participantTable-entry')
		:node(OpponentDisplay.BlockOpponent(Table.merge(additionalProps, {
			dq = entry.dq,
			note = entry.note,
			showPlayerTeam = self.config.showTeams,
			opponent = entry.opponent,
			oneLine = true,
		})))

	return DisplayHelper.addOpponentHighlight(entryNode, entry.opponent)
end

return CustomParticipantTable
