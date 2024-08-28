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
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Import = Lua.import('Module:ParticipantTable/Import')
local PlayerExt = Lua.import('Module:Player/Ext')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local pageVars = PageVariableNamespace('ParticipantTable')
local prizePoolVars = PageVariableNamespace('PrizePool')

---@class ParticipantTableConfig
---@field lpdbPrefix string?
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
---@field width string
---@field columnWidth string
---@field showTitle boolean only applies for the title of the whole table

---@class ParticipantTableSection
---@field config ParticipantTableConfig
---@field entries ParticipantTableEntry

---@class ParticipantTableEntry
---@field opponent standardOpponent
---@field name string
---@field note string?
---@field dq boolean
---@field inputIndex integer?

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

---@param args table
---@param parentConfig ParticipantTableConfig?
---@return ParticipantTableConfig
function ParticipantTable.readConfig(args, parentConfig)
	parentConfig = parentConfig or {}

	local config = {
		lpdbPrefix = args.lpdbPrefix or parentConfig.lpdbPrefix or Variables.varDefault('lpdbPrefix'),
		noStorage = Logic.readBool(args.noStorage or parentConfig.noStorage or
			Variables.varDefault('disable_LPDB_storage') or not Namespace.isMain()),
		matchGroupSpec = TournamentStructure.readMatchGroupsSpec(args),
		syncPlayers = Logic.nilOr(Logic.readBoolOrNil(args.syncPlayers), parentConfig.syncPlayers, true),
		showCountBySection = Logic.readBool(args.showCountBySection or parentConfig.showCountBySection),
		count = tonumber(args.count),
		colSpan = parentConfig.colSpan or tonumber(args.colspan) or 4,
		onlyNotable = Logic.readBool(args.onlyNotable or parentConfig.onlyNotable),
		resolveDate = args.date or parentConfig.resolveDate or DateExt.getContextualDate(),
		sortPlayers = Logic.readBool(args.sortPlayers or parentConfig.sortPlayers),
		sortOpponents = Logic.nilOr(Logic.readBoolOrNil(args.sortOpponents), parentConfig.sortOpponents, true),
		showTeams = not Logic.readBool(args.disable_teams),
		title = args.title,
		importOnlyQualified = Logic.readBool(args.onlyQualified),
		display = not Logic.readBool(args.hidden),
		showTitle = not Logic.readBool(args.hideTitle),
	}

	config.width = parentConfig.width
	if not config.width then
		local columnWidth = parentConfig.columnWidth or tonumber(args.entrywidth) or config.showTeams and 212 or 156
		config.width = (columnWidth * config.colSpan) .. 'px'
	end
	config.columnWidth = config.columnWidth or ((100 / config.colSpan) .. '%')

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

---@param args table
function ParticipantTable:readSection(args)
	local config = self.readConfig(args, self.config)
	local section = {config = config}

	local entriesByName = {}
	local tbds = {}
	Table.mapArgumentsByPrefix(args, {'p', 'player'}, function(key, index)
		local entry = self:readEntry(args, key, index, config)

		if entry.opponent and Opponent.isTbd(entry.opponent) then
			table.insert(tbds, entry)
			--needed so index is increased
			return entry
		end

		if entriesByName[entry.name] then
			error('Duplicate Input "|' .. key .. '=' .. args[key] .. '"')
		end

		entriesByName[entry.name] = entry

		--needed so index is increased
		return entry
	end)

	section.entries = Array.map(Import.importFromMatchGroupSpec(config, entriesByName), function(entry)
		entry.opponent = Opponent.resolve(entry.opponent, config.resolveDate, {
			syncPlayer = config.syncPlayers,
			overwritePageVars = true,
		})
		self:setCustomPageVariables(entry, config)
		return entry
	end)

	Array.sortInPlaceBy(section.entries, function(entry)
		return config.sortOpponents and entry.name:lower() or entry.inputIndex or -1
	end)

	Array.extendWith(section.entries, tbds)

	table.insert(self.sections, section)
end

---@param entry ParticipantTableEntry
---@param config ParticipantTableConfig
function ParticipantTable:setCustomPageVariables(entry, config)
end

---@param sectionArgs table
---@param key string|number
---@param index number
---@param config ParticipantTableConfig
---@return ParticipantTableEntry
function ParticipantTable:readEntry(sectionArgs, key, index, config)
	local prefix = 'p' .. index
	local valueFromArgs = function(postfix)
		return sectionArgs[key .. postfix] or sectionArgs[prefix .. postfix]
	end

	--if not a json assume it is a solo opponent
	local opponentArgs = Json.parseIfTable(sectionArgs[key]) or {
		type = Opponent.solo,
		name = sectionArgs[key],
		link = valueFromArgs('link'),
		flag = valueFromArgs('flag'),
		team = valueFromArgs('team'),
		dq = valueFromArgs('dq'),
		note = valueFromArgs('note'),
	}

	assert(Opponent.isType(opponentArgs.type) and opponentArgs.type ~= Opponent.team,
		'Missing or unsupported opponent type for "' .. sectionArgs[key] .. '"')

	local opponent = Opponent.readOpponentArgs(opponentArgs) or {}

	if config.sortPlayers and opponent.players then
		table.sort(opponent.players, function (player1, player2)
			local name1 = (player1.displayName or player1.pageName):lower()
			local name2 = (player2.displayName or player2.pageName):lower()
			return name1 < name2
		end)
	end

	return {
		dq = Logic.readBool(opponentArgs.dq),
		note = opponentArgs.note,
		opponent = opponent,
		name = Opponent.toName(opponent),
		inputIndex = index,
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

		if section.config.noStorage or Opponent.isTbd(entry.opponent) or Opponent.isEmpty(entry.opponent) then return end

		if placements[lpdbData.opponentname] then
			lpdbData = Table.deepMerge(
				lpdbData,
				placements[lpdbData.opponentname]
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

---@return Html?
function ParticipantTable:create()
	local config = self.config

	if not config.display then return end

	self.display = mw.html.create('div')
		:addClass('participantTable')
		:css('max-width', '100%!important')
		:css('width', config.width)
		:node(config.showTitle and
			mw.html.create('div'):addClass('participantTable-title'):wikitext(config.title or 'Participants')
			or nil)

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

	self.display:node(self.newSectionNode():node(self:sectionTitle(section, sectionEntryCount)))

	if Table.isEmpty(section.entries) then
		self.display:node(self.newSectionNode():node(self:tbd()))
		return
	end

	local sectionNode = ParticipantTable.newSectionNode()

	Array.forEach(entries, function(entry, entryIndex)
		sectionNode:node(self:displayEntry(entry):css('width', self.config.columnWidth))
	end)

	local tbdsAdded = 0
	if section.config.count and section.config.count > sectionEntryCount then
		Array.forEach(Array.range(sectionEntryCount + 1, section.config.count), function(index)
			tbdsAdded = tbdsAdded + 1
			sectionNode:node(self:tbdEntry():css('width', self.config.columnWidth))
		end)
	end

	local currentColumn = (#entries + tbdsAdded) % self.config.colSpan
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
function ParticipantTable:sectionTitle(section, amountOfEntries)
	if Logic.isEmpty(section.config.title) or section.config.title == self.config.title then
		return
	end

	local title = mw.html.create('div'):addClass('participantTable-title'):wikitext(section.config.title)

	if not section.config.showCountBySection then return title end

	return title:tag('i'):wikitext(' (' .. (section.config.count or amountOfEntries) .. ')'):done()
end

---@return Html
function ParticipantTable:tbdEntry()
	return mw.html.create('div')
		:addClass('participantTable-entry')
		:node(OpponentDisplay.BlockOpponent{
			opponent = Opponent.tbd(),
		})
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
