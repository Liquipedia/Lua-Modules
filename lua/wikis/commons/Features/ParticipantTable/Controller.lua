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

local FactionTable = Lua.import('Module:Features/ParticipantTable/Components/FactionTable')
local ParticipantTable = Lua.import('Module:Features/ParticipantTable/Components/Table')
local Wrapper = Lua.import('Module:Features/ParticipantTable/Components/Wrapper')

local Controller = {}

---@param frame Frame
---@param CustomConfig {
---adjustLpdbData?: fun(lpdbData: table, entry: ParticipantTableEntry, config: ParticipantTableConfig)}
---@return VNode?
function Controller.execute(frame, CustomConfig)
	local args = Arguments.getArgs(frame)
	local config, sections = Controller._parseAndProcess(args)

	if config.storage then
		Store.run(sections, config, CustomConfig.adjustLpdbData)
	end

	if not config.display then return end

	local shouldDisplayAsFactionTable = Util.shouldDisplayAsFactionTable(sections, config)


	local displayComponent = shouldDisplayAsFactionTable and FactionTable or ParticipantTable

	local factionNumbers = Util.getFactionNumbers(sections, config)
	local factionColumns = Util.getFactionColumns(config, factionNumbers)
	if shouldDisplayAsFactionTable then
		factionNumbers = Util.getFactionNumbers(sections, config)
		factionColumns = Util.getFactionColumns(config, factionNumbers)
	end

	return Wrapper{
		hasSeed = Util.hasSeed(sections),
		sections = sections,
		config = config,
		displayComponent = displayComponent,
		factionColumns = factionColumns,
		factionNumbers = factionNumbers,
	}
end

---@param args table
---@return ParticipantTableConfig
---@return ParticipantTableSection[]
function Controller._parseAndProcess(args)
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

	sections = Util.filterOnlyNotables(sections)

	return config, sections
end

return Controller
