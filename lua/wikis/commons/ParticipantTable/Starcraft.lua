---
-- @Liquipedia
-- page=Module:ParticipantTable/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local FactionTable = Lua.import('Module:Features/ParticipantTable/Components/FactionTable')
local Util = Lua.import('Module:Features/ParticipantTable/Lib/Util')

---@class StarcraftParticipantTable: ParticipantTable
---@operator call(Frame): StarcraftParticipantTable
---@field config ParticipantTableConfig
---@field sections ParticipantTableSection[]
local StarcraftParticipantTable = Class.new(ParticipantTable)

---@param frame Frame
---@return VNode?
function StarcraftParticipantTable.run(frame)
	return StarcraftParticipantTable(frame):read():store():create()
end

---@return VNode?
function StarcraftParticipantTable:create()
	if Util.shouldDisplayAsFactionTable(self.sections, self.config) then
		return self:createSoloFactionTable()
	end
	return ParticipantTable.create(self)
end

---@return VNode?
function StarcraftParticipantTable:createSoloFactionTable()
	local config = self.config

	if not config.display then return end

	local factionNumbers = Util.getFactionNumbers(self.sections, self.config)
	local factionColumns = Util.getFactionColumns(config, factionNumbers)

	return FactionTable{
		config = self.config,
		factionColumns = factionColumns,
		factionNumbers = factionNumbers,
		sections = self.sections,
	}
end

return StarcraftParticipantTable
