---
-- @Liquipedia
-- wiki=commons
-- page=Module:ParticipantTable/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--can not name it `Module:ParticipantTable` due to that already existing on some wikis

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local OpponentLibraries = require('OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local TournamentStructure = Lua.import('Module:TournamentStructure', {requireDevIfEnabled = true})
local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})

local pageVars = PageVariableNamespace('StarcraftParticipantTable')

---@class ParticipantTable
---@operator call(Frame): ParticipantTable
---@field args table
---@field config ParticipantTableConfig
---@field display Html?
---@field sections ParticipantTableSection[]
local ParticipantTable = Class.new(
	function(self, frame)
		self.args = Arguments.getArgs(frame)
end)

---@param frame Frame
---@return Html?
function ParticipantTable.run(frame)
	return ParticipantTable(frame):init():store():create()
end

---@return ParticipantTable
function ParticipantTable:init()
	self.config = self.readConfig(self.args)
	self:readSections()

	return self
end

---@class ParticipantTableConfig
---@field lpdbPrefix string
---@field noStorage boolean
---@field matchGroupSpec table?
---@field syncPlayers boolean
---@field showCountBySection boolean
---@field onlyNotable boolean
---@field colSpan number
---@field resolveDate string
---@field sortPlayers boolean sort players within an opponent
---@field sortOpponents boolean
---@field showTeams boolean
---@field title string
---@field columnWidth number? width of the column in px
---@field importOnlyQualified boolean?
---@field display boolean

---@param args table
---@param parentConfig ParticipantTableConfig?
---@return ParticipantTableConfig
function ParticipantTable.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}
	local config = {
		lpdbPrefix = args.lpdbPrefix or parentConfig.lpdbPrefix or Variables.varDefault('lpdbPrefix') or '',
		noStorage = Logic.readBool(args.noStorage or parentConfig.noStorage or
			Variables.varDefault('disable_LPDB_storage') or not Namespace.isMain()),
		matchGroupSpec = TournamentStructure.readMatchGroupsSpec(args),
		syncPlayers = Logic.nilOr(Logic.readBoolOrNil(args.syncPlayers), parentConfig.syncPlayers, true),
		showCountBySection = Logic.readBool(args.showCountBySection or parentConfig.showCountBySection),
		colSpan = tonumber(args.colspan) or parentConfig.colSpan or 4,
		onlyNotable = Logic.readBool(args.onlyNotable or parentConfig.onlyNotable),
		resolveDate = args.date or parentConfig.resolveDate or DateExt.getContextualDate(),
		sortPlayers = Logic.readBool(args.sortPlayers or parentConfig.sortPlayers),
		sortOpponents = Logic.readBool(args.sortOpponents or parentConfig.sortOpponents),
		showTeams = not Logic.nilOr(Logic.readBoolOrNil(args.disable_teams), not parentConfig.showTeams),
		title = args.title,
		importOnlyQualified = Logic.readBool(args.onlyQualified),
		display = not Logic.readBool(args.hidden)
	}

	config.columnWidth = tonumber(args.entrywidth) or config.showTeams and 215 or 155

	return config
end

function ParticipantTable:readSections()
	self.sections = {}
	Array.forEach(self:fetchSectionsArgs(), function(sectionArgs)
		self:readSection(sectionArgs)
	end)
end

---@return table[]
function ParticipantTable:fetchSectionsArgs()
	local args = self.args

	pageVars:set('stashArgs', '1')

	-- make sure that all sections stashArgs
	for _, potentialSection in ipairs(args) do
		potentialSection = potentialSection
	end

	-- retrieve sectionsArgs
	local sectionsArgs = Template.retrieveReturnValues('ParticipantTable')
	pageVars:delete('stashArgs')

	--case no sections: use whole table as first section
	if Table.isEmpty(sectionsArgs) then
		return {args}
	end

	return sectionsArgs
end

---@class ParticipantTableSection
---@field config ParticipantTableConfig
---@field entries ParticipantTableEntry

---@param args table
function ParticipantTable:readSection(args)
	local section = {config = self.readConfig(args, self.config)}

	local keys = Array.filter(Array.extractKeys(args), function(key)
		return String.contains(key, '^%d+$') or
			String.contains(key, '^p%d+$') or
			String.contains(key, '^player%d+$')
	end)

	local entries = {}
	local entriesByName = {}

	--need custom sort so it doesn't compare number with string
	local sortKeys = function(tbl, key1, key2) return tostring(key1) < tostring(key2) end

	for _, key in Table.iter.spairs(keys, sortKeys) do
		local entry = self:readEntry(args, key, section.config)
		if not entriesByName[entry.name] then
			table.insert(entries, entry)
			entriesByName[entry.name] = entries[#entries]
		else
			error('Duplicate Input "|' .. key .. '=' .. args[key] .. '"')
		end
	end

	if section.config.matchGroupSpec then
		someBS
		--import shit
		--needs to merge input and imported --> entriesByName needed!
	end

	section.entries = Array.map(entries, function(entry)
		entry.opponent = Opponent.resolve(entry.opponent, entry.date, {syncPlayer = section.config.syncPlayers})
		return entry
	end)

	table.insert(self.sections, section)
end

---@class ParticipantTableEntry
---@field opponent standardOpponent
---@field name string

---@param sectionArgs table
---@param key string|number
---@param config any
---@return ParticipantTableEntry
function ParticipantTable:readEntry(sectionArgs, key, config)
	--if not a json assume it is a solo opponent
	local opponentArgs = Json.parseIfTable(sectionArgs[key]) or Logic.isNumeric(key) and {
		type = Opponent.solo,
		name = sectionArgs[key],
	} or {
		type = Opponent.solo,
		name = sectionArgs[key],
		link = sectionArgs[key .. 'link'],
		flag = sectionArgs[key .. 'flag'],
		team = sectionArgs[key .. 'team'],
	}

	assert(Opponent.isType(opponentArgs.type) and opponentArgs.type ~= Opponent.team,
		'Missing or unsupported opponent type for "' .. sectionArgs[key] .. '"')

	local opponent = Opponent.readOpponentArgs(opponentArgs)

	if config.sortPlayers and opponent.players then
		table.sort(opponent.players, function (player1, player2)
			local name1 = (player1.displayName or player1.name):lower()
			local name2 = (player2.displayName or player2.name):lower()
			return name1 < name2
		end)
	end

	return {opponent = opponent, name = Opponent.toName(opponent)}
end

---@return ParticipantTable
function ParticipantTable:store()
	if self.config.noStorage then return self end

	local lpdbTournamentData = {
		tournament = Variables.varDefault('tournament_name'),
		parent = Variables.varDefault('tournament_parent'),
		series = Variables.varDefault('tournament_series'),
		shortname = Variables.varDefault('tournament_tickername'),
		startdate = Variables.varDefault('tournament_startdate'),
		mode = Variables.varDefault('tournament_mode'),
		type = Variables.varDefault('tournament_type'),
		liquipediatier = Variables.varDefault('tournament_liquipediatier'),
		liquipediatiertype = Variables.varDefault('tournament_liquipediatiertype'),
		publishertier = Variables.varDefault('tournament_publishertier'),
		icon = Variables.varDefault('tournament_icon'),
		icondark = Variables.varDefault('tournament_icondark'),
		game = Variables.varDefault('tournament_game'),
		prizepoolindex = tonumber(Variables.varDefault('prizepool_index')) or 0,
	}

	local placements = self:getPlacements()

	Array.forEach(self.sections, function(section) Array.forEach(section.entries, function(entry)
		local lpdbData = Opponent.toLpdbStruct(entry.opponent)

		if placements[lpdbData.opponentname] or section.config.noStorage or
			Opponent.isTbd(entry.opponent) or Opponent.isEmpty(entry.opponent) then return end


		lpdbData = Table.merge(lpdbTournamentData, lpdbData, {
			extradata = self:buildExtradata(lpdbData),
			date = entry.date,
		})

		mw.ext.LiquipediaDB.lpdb_placement(self:objectName(lpdbData), Json.stringifySubTables(lpdbData))
	end) end)

	return self
end

---Get placements already set on the page from prize pools
---@return table<string, true>
function ParticipantTable:getPlacements()
	local placements = {}
	Array.forEach(mw.ext.LiquipediaDB.lpdb('placement', {
		limit = 5000,
		conditions = '[[placement::!]] AND [[pagename::' .. string.gsub(mw.title.getCurrentTitle().text, ' ', '_') .. ']]',
	}), function(placement) placements[placement.opponentname] = true end)

	return placements
end

---@param lpdbData table
---@return string
function ParticipantTable:objectName(lpdbData)
	return 'ranking_' .. self.config.lpdbPrefix .. '_' .. lpdbData.prizepoolindex .. '_' .. lpdbData.opponentname
end

---@param lpdbData table
---@return table?
function ParticipantTable:buildExtradata(lpdbData)
end

---@return Html?
function ParticipantTable:create()
	if not self.config.display then return end

	self.display = mw.html.create('div')
		:addClass('opponent-list')
		:css('grid-template-columns', 'repeat(' .. self.config.colSpan .. ', 1fr)')
		:css('max-width', '100%')
		:node(ParticipantTable.textCell(self.config.title or 'Participants'):addClass('opponent-list-title'))

	Array.forEach(self.sections, function(section) ParticipantTable:displaySection(section) end)

	return self.display
end

function ParticipantTable:displaySection(section)

	local entries = section.config.onlyNotable and Array.filter(section.entries, function(entry)
		return self.isNotable(entry)
	end) or section.entries

	local sectionNode = mw.html.create('div')
		:addClass('opponent-list-section')
		:node(self.sectionTitle(section, #entries))

	if section.config.sortOpponents then
		Array.sortInPlaceBy(entries, function(entry) return entry.name:lower() end)
	end

	if Table.isEmpty(section.entries) then
		return sectionNode:node(self.tbd())
	end

	Array.forEach(entries, function(entry)
		sectionNode:node(self:displayEntry(entry))
	end)

	local currentColumn = (#entries % self.config.colSpan) + 1

	Array.forEach(Array.range(currentColumn, self.config.colSpan),
		function() sectionNode:node(self.empty()) end)

	return sectionNode
end

---@param text string|number
---@return Html
function ParticipantTable.textCell(text)
	return mw.html.create('div'):addClass('opponent-list-cell')
		:node(mw.html.create('div'):addClass('opponent-list-cell-content'):wikitext(text))
end

---@return Html
function ParticipantTable.tbd()
	return ParticipantTable.textCell('To be determined'):addClass('opponent-list-tbd')
end

---@return Html
function ParticipantTable.empty()
	return ParticipantTable.textCell(''):addClass('opponent-list-cell-content')
end

---@param section ParticipantTableSection
---@param amountOfEntries number
---@return Html?
function ParticipantTable.sectionTitle(section, amountOfEntries)
	if Logic.isEmpty(section.config.title) then return end

	local sectionTitle = ParticipantTable.textCell(section.config.title):addClass('opponent-list-section-title')

	if not section.config.showCountBySection then return sectionTitle end

	return sectionTitle:tag('i'):wikitext(' (' .. amountOfEntries .. ')'):done()
end

---@param entry ParticipantTableEntry
---@return Html
function ParticipantTable:displayEntry(entry)
	return mw.html.create('div')
	:addClass('opponent-list-cell opponent-list-entry brkts-opponent-hover')
	:attr('aria-label', entry.name)
	:node(OpponentDisplay.BlockOpponent{
		showPlayerTeam = self.config.showTeams,
		opponent = entry.opponent,
	})
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
