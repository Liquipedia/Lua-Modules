---
-- @Liquipedia
-- page=Module:Features/ParticipantTable/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')

local Import = Lua.import('Module:Features/ParticipantTable/Api/Import')
local ImportParser = Lua.import('Module:Features/ParticipantTable/Lib/ParseImported')
local Parser = Lua.import('Module:Features/ParticipantTable/Lib/ParseInput')
local Store = Lua.import('Module:Features/ParticipantTable/Api/Storage')
local Util = Lua.import('Module:Features/ParticipantTable/Lib/Util')

local Display = Lua.import('Module:Features/ParticipantTable/Components/Wrapper')
local FactionTable = Lua.import('Module:Features/ParticipantTable/Components/FactionTable')

local Controller = {}

---@param frame Frame
---@param CustomConfig {
---adjustLpdbData?: fun(lpdbData: table, entry: ParticipantTableEntry, config: ParticipantTableConfig)}
---@return VNode?
function Controller.execute(frame, CustomConfig)
	local args = Arguments.getArgs(frame)

	local config = Parser.readConfig(args)

	local sections = Parser.readSections(args, config)

	Array.forEach(sections, function(section)
		local matchRecords = Import.fromMatchGroupSpec(section.config.matchGroupSpec)
		Array.extendWith(section.entries, ImportParser.parseImported(section.config, section.entries, matchRecords))
		Util.backFillEntries(section)
		Util.sortOpponents(section)
		Array.forEach(section.entries, function(entry)
			if config.isRandomEvent then
				Store.setFactionVariableAsRandom(entry)
			end
		end)
	end)

	Util.filterOnlyNotables(sections)

	if config.storage then
		Store.run(sections, config, CustomConfig.adjustLpdbData)
	end

	if not config.display then return end

	if not Util.shouldDisplayAsFactionTable(sections, config) then
		return Display{
			hasSeed = Util.hasSeed(sections),
			sections = sections,
			config = config,
		}
	end

	local factionNumbers = Util.getFactionNumbers(sections, config)
	local factionColumns = Util.getFactionColumns(config, factionNumbers)

	-- todo: add faction wrapper that works with seeding table
	-- for now in factionTable mode seeding table is not supported
	return FactionTable{
		config = config,
		factionColumns = factionColumns,
		factionNumbers = factionNumbers,
		sections = sections,
	}
end

return Controller
