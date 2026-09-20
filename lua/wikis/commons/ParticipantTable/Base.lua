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
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local Table = Lua.import('Module:Table')
local Tournament = Lua.import('Module:Tournament')
local Variables = Lua.import('Module:Variables')

local Import = Lua.import('Module:Features/ParticipantTable/Api/Import')
local ImportParser = Lua.import('Module:Features/ParticipantTable/Lib/ParseImported')
local Parser = Lua.import('Module:Features/ParticipantTable/Lib/ParseInput')
local Util = Lua.import('Module:Features/ParticipantTable/Lib/Util')

local Display = Lua.import('Module:Features/ParticipantTable/Components/Wrapper')

local prizePoolVars = PageVariableNamespace('PrizePool')

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
			self:setCustomPageVariables(entry, section.config)
		end)
	end)
	self.hasSeeds = Util.hasSeed(self.sections)

	return self
end

---@param entry ParticipantTableEntry
---@param config ParticipantTableConfig
function ParticipantTable:setCustomPageVariables(entry, config)
end

---@return self
function ParticipantTable:store()
	if self.config.noStorage then return self end

	local tournamentContext = Tournament.partialTournamentFromContext()

	local lpdbTournamentData = {
		tournament = tournamentContext.fullName,
		parent = tournamentContext.pageName,
		series = tournamentContext.series,
		startdate = Variables.varDefault('tournament_startdate'),
		mode = tournamentContext.mode,
		type = tournamentContext.type,
		liquipediatier = tournamentContext.liquipediaTier,
		liquipediatiertype = tournamentContext.liquipediaTierType,
		publishertier = tournamentContext.publisherTier,
		icon = tournamentContext.icon,
		icondark = tournamentContext.iconDark,
		game = tournamentContext.game,
		prizepoolindex = tonumber(Variables.varDefault('prizepool_index')) or 0,
	}

	local placements = self:getPlacements()

	---@param section ParticipantTableSection
	---@param opponent standardOpponent
	---@return boolean
	local shouldNotStoreOpponent = function(section, opponent)
		return section.config.noStorage or
			opponent.type == Opponent.team or
			Opponent.isTbd(opponent) or
			Opponent.isEmpty(opponent)
	end

	Array.forEach(self.sections, function(section) Array.forEach(section.entries, function(entry)
		if shouldNotStoreOpponent(section, entry.opponent) then return end

		local lpdbData = Opponent.toLpdbStruct(entry.opponent)
		local placement = placements[lpdbData.opponentname]

		if placement then
			lpdbData = Table.deepMerge(
				lpdbData,
				placement
			)
		else
			lpdbData = Table.merge(
				lpdbTournamentData,
				lpdbData,
				{date = section.config.resolveDate, extradata = {dq = entry.dq and 'true' or nil}}
			)
		end

		self:adjustLpdbData(lpdbData, entry, section.config)

		mw.ext.LiquipediaDB.lpdb_placement(self:objectName(lpdbData), Json.stringifySubTables(lpdbData))
	end) end)

	return self
end

---Get placements already set on the page from prize pools ABOVE the participant table
---@return table<string, placement>
function ParticipantTable:getPlacements()
	local placements = {}
	local maxPrizePoolIndex = tonumber(Variables.varDefault('prizepool_index')) or 0

	for prizePoolIndex = 1, maxPrizePoolIndex do
		Array.forEach(Json.parseIfTable(prizePoolVars:get('placementRecords.' .. prizePoolIndex)) or {}, function(placement)
			placements[placement.opponentname] = placement
		end)
	end

	return placements
end

---@param lpdbData table
---@return string
function ParticipantTable:objectName(lpdbData)
	--this objectName comes from lpdbData passed along as wiki vars, e.g. sc, sc2, sg
	if Logic.isNotEmpty(lpdbData.objectName) then return lpdbData.objectName end

	--this objectName comes from queried lpdb data and has a prefixed pageid
	if Logic.isNotEmpty(lpdbData.objectname) then
		--remove then prefixed pageid from the objectName
		local objectName = lpdbData.objectname:gsub('^%d*_', '')
		return objectName
	end

	local lpdbPrefix = self.config.lpdbPrefix and ('_' .. self.config.lpdbPrefix) or ''
	return 'ranking' .. lpdbPrefix .. lpdbData.prizepoolindex .. '_' .. lpdbData.opponentname
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

	Array.forEach(self.sections, function(section)
		if not section.config.onlyNotable then return end
		section.entries = self.filterOnlyNotables(section.entries)
	end)

	return Display{
		hasSeed = self.hasSeeds,
		sections = self.sections,
		config = self.config,
	}
end

---@param entries ParticipantTableEntry[]
---@return ParticipantTableEntry[]
function ParticipantTable.filterOnlyNotables(entries)
	return Array.filter(entries, function(entry) return ParticipantTable.isNotable(entry) end)
end

---@param entry ParticipantTableEntry
---@return boolean
function ParticipantTable.isNotable(entry)
	return Array.any(entry.opponent.players or {}, ParticipantTable.isNotablePlayer)
end

---@param player standardPlayer
---@return boolean
function ParticipantTable.isNotablePlayer(player)
	return Logic.isNotEmpty(player.pageName) and PlayerExt.fetchPlayerFlag(player.pageName) ~= nil
end

return ParticipantTable
