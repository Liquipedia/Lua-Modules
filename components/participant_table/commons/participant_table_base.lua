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

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Import = Lua.import('Module:ParticipantTable/Import', {requireDevIfEnabled = true})
local PlayerExt = Lua.import('Module:Player/Ext', {requireDevIfEnabled = true})
local TournamentStructure = Lua.import('Module:TournamentStructure', {requireDevIfEnabled = true})

local pageVars = PageVariableNamespace('ParticipantTable')

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
	return ParticipantTable(frame):read():store():create()
end

---@return self
function ParticipantTable:read()
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
---@field count number?
---@field colSpan number
---@field resolveDate string
---@field sortPlayers boolean sort players within an opponent
---@field sortOpponents boolean
---@field showTeams boolean
---@field title string?
---@field importOnlyQualified boolean?
---@field display boolean
---@field columnWidth number? width of the column in px

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
		count = tonumber(args.count),
		colSpan = tonumber(args.colspan) or parentConfig.colSpan or 4,
		onlyNotable = Logic.readBool(args.onlyNotable or parentConfig.onlyNotable),
		resolveDate = args.date or parentConfig.resolveDate or DateExt.getContextualDate(),
		sortPlayers = Logic.readBool(args.sortPlayers or parentConfig.sortPlayers),
		sortOpponents = Logic.nilOr(Logic.readBoolOrNil(args.sortOpponents), parentConfig.sortOpponents, true),
		showTeams = not Logic.readBool(args.disable_teams),
		title = args.title,
		importOnlyQualified = Logic.readBool(args.onlyQualified),
		display = not Logic.readBool(args.hidden)
	}

	config.columnWidth = tonumber(args.entrywidth) or config.showTeams and 212 or 156

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
	for _, potentialSection in pairs(args) do
		ParticipantTable._stashArgs(potentialSection)
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

---access the args so it stashes
---@param potentialSection string
---@return string
function ParticipantTable._stashArgs(potentialSection)
	return potentialSection
end


---@class ParticipantTableSection
---@field config ParticipantTableConfig
---@field entries ParticipantTableEntry

---@param args table
function ParticipantTable:readSection(args)
	local config = self.readConfig(args, self.config)
	local section = {config = config}

	local keys = Array.filter(Array.extractKeys(args), function(key)
		return String.contains(key, '^%d+$') or
			String.contains(key, '^p%d+$') or
			String.contains(key, '^player%d+$')
	end)

	local entriesByName = {}
	Array.forEach(keys, function(key)
		local entry = self:readEntry(args, key, config)
		if entriesByName[entry.name] then
			error('Duplicate Input "|' .. key .. '=' .. args[key] .. '"')
		end

		entriesByName[entry.name] = entry
	end)

	section.entries = Array.map(Import.importFromMatchGroupSpec(config, entriesByName), function(entry)
		entry.opponent = Opponent.resolve(entry.opponent, config.resolveDate, {syncPlayer = config.syncPlayers})
		return entry
	end)

	Array.sortInPlaceBy(section.entries, function(entry)
		return config.sortOpponents and entry.name:lower() or entry.inputIndex or -1
	end)

	table.insert(self.sections, section)
end

---@class ParticipantTableEntry
---@field opponent standardOpponent
---@field name string
---@field note string?
---@field dq boolean

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

	return {
		dq = Logic.readBool(opponentArgs.dq or sectionArgs[key .. 'dq']),
		note = opponentArgs.note or sectionArgs[key .. 'note'],
		opponent = opponent,
		name = Opponent.toName(opponent),
		inputIndex = tonumber(string.match(key, '%d+')),
	}
end

---@return self
function ParticipantTable:store()
	if self.config.noStorage then return self end

	local lpdbTournamentData = {
		tournament = Variables.varDefault('tournament_name'),
		parent = Variables.varDefault('tournament_parent'),
		series = Variables.varDefault('tournament_series'),
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


		lpdbData = Table.merge(lpdbTournamentData, lpdbData, {date = section.config.resolveDate, extradata = {}})

		ParticipantTable:adjustLpdbData(lpdbData, entry, section.config)

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
---@param entry ParticipantTableEntry
---@param config ParticipantTableConfig
function ParticipantTable:adjustLpdbData(lpdbData, entry, config)
end

---@return Html?
function ParticipantTable:create()
	local config = self.config

	if not config.display then return end

	self.display = mw.html.create('div')
		:addClass('participantTable')
		:css('max-width', '100%!important')
		:css('width', (config.colSpan * config.columnWidth + 1) .. 'px')
		:node(mw.html.create('div'):addClass('participantTable-title'):wikitext(config.title or 'Participants'))

	Array.forEach(self.sections, function(section) self:displaySection(section) end)

	return self.display
end

---@return Html
function ParticipantTable.newSectionNode()
	return mw.html.create('div'):addClass('participantTable-row')
end

---@param section ParticipantTableSection
function ParticipantTable:displaySection(section)
	local entries = section.config.onlyNotable and self.filterOnlyNotables(section.entries) or section.entries

	local sectionEntryCount = #Array.filter(entries, function(entry) return not entry.dq end)

	self.display:node(self.newSectionNode():node(self.sectionTitle(section, sectionEntryCount)))

	if Table.isEmpty(section.entries) then
		self.display:node(self.newSectionNode():node(self:tbd()))
		return
	end

	local sectionNode = ParticipantTable.newSectionNode()

	Array.forEach(entries, function(entry, entryIndex)
		sectionNode:node(self:displayEntry(entry):css('width', self.config.columnWidth .. 'px'))
	end)

	local currentColumn = (#entries) % self.config.colSpan
	if currentColumn ~= 0 then
		Array.forEach(Array.range(currentColumn + 1, self.config.colSpan), function() sectionNode:node(self:empty()) end)
	end

	self.display:node(sectionNode)
end

---@return Html
function ParticipantTable:tbd()
	return mw.html.create('div')
		:addClass('participantTable-tbd')
		:wikitext('To be determined')
end

---@return Html
function ParticipantTable:empty()
	return mw.html.create('div'):addClass('participantTable-entry participantTable-empty')
end

---@param section ParticipantTableSection
---@param amountOfEntries number
---@return Html?
function ParticipantTable.sectionTitle(section, amountOfEntries)
	if Logic.isEmpty(section.config.title) then return end

	local title = mw.html.create('div'):addClass('participantTable-title'):wikitext(section.config.title)

	if not section.config.showCountBySection then return title end

	return title:tag('i'):wikitext(' (' .. (section.config.count or amountOfEntries) .. ')'):done()
end

---@param entry ParticipantTableEntry
---@param additionalProps table?
---@return Html
function ParticipantTable:displayEntry(entry, additionalProps)
	additionalProps = additionalProps or {}

	return mw.html.create('div')
		:addClass('participantTable-entry brkts-opponent-hover')
		:attr('aria-label', entry.name)
		:node(OpponentDisplay.BlockOpponent(Table.merge(additionalProps, {
			dq = entry.dq,
			note = entry.note,
			showPlayerTeam = self.config.showTeams,
			opponent = entry.opponent,
		})))
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
