---
-- @Liquipedia
-- page=Module:ParticipantTable/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--can not name it `Module:ParticipantTable` due to that already existing on some wikis

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Import = Lua.import('Module:Features/ParticipantTable/Api/Import')
local ImportParser = Lua.import('Module:Features/ParticipantTable/Lib/ParseImported')
local Parser = Lua.import('Module:Features/ParticipantTable/Lib/ParseInput')
local Store = Lua.import('Module:Features/ParticipantTable/Api/Storage')
local Util = Lua.import('Module:Features/ParticipantTable/Lib/Util')

local Display = Lua.import('Module:Features/ParticipantTable/Components/Wrapper')

---@class ParticipantTable: BaseClass
---@operator call(Frame): ParticipantTable
---@field args table
---@field config ParticipantTableConfig
---@field sections ParticipantTableSection[]
---@field hasSeeds boolean
local ParticipantTable = Class.new(
	function(self, frame)
		self.args = Arguments.getArgs(frame)
end)

---@param frame Frame
---@return VNode?
function ParticipantTable.run(frame)
	return ParticipantTable(frame):read():store():create()
end

---@return self
function ParticipantTable:read()
	self.config = Parser.readConfig(self.args)
	self.sections = Parser.readSections(self.args, self.config)

	Array.forEach(self.sections, function(section)
		local matchRecords = Import.fromMatchGroupSpec(section.config.matchGroupSpec)
		Array.extendWith(section.entries, ImportParser.parseImported(section.config, section.entries, matchRecords))
		Util.backFillEntries(section)
		Util.sortOpponents(section)
		Array.forEach(section.entries, function(entry)
			if self.config.isRandomEvent then
				Store.setFactionVariableAsRandom(entry)
			end
		end)
	end)
	Util.filterOnlyNotables(self.sections)
	self.hasSeeds = Util.hasSeed(self.sections)

	return self
end

---@return self
function ParticipantTable:store()
	if self.config.noStorage then return self end

	Store.run(self.sections, self.config, function(lpdbData, entry, config)
		return self:adjustLpdbData(lpdbData, entry, config)
	end)

	return self
end

---@param lpdbData table
---@param entry ParticipantTableEntry
---@param config ParticipantTableConfig
function ParticipantTable:adjustLpdbData(lpdbData, entry, config)
end

---@return VNode?
function ParticipantTable:create()
	local config = self.config

	if not config.display then return end

	return Display{
		hasSeed = self.hasSeeds,
		sections = self.sections,
		config = self.config,
	}
end

return ParticipantTable
