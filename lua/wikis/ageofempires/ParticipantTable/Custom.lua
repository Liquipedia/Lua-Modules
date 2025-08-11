---
-- @Liquipedia
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

---@class AoEParticipantTableEntry: ParticipantTableEntry
---@field seed integer?

---@class AoEParticipantTableSection: ParticipantTableSection
---@field entries AoEParticipantTableEntry[]

---@class AoEParticipantTable: ParticipantTable
---@field hasSeeds boolean
---@field _createSeedList function
---@field _createTitle function

local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

local Opponent = Lua.import('Module:Opponent/Custom')

local AoEParticipantTable = {}

---@param frame Frame
---@return Html?
function AoEParticipantTable.run(frame)
	local participantTable = ParticipantTable(frame) --[[@as AoEParticipantTable]]
	participantTable.readEntry = AoEParticipantTable.readEntry
	participantTable:read():store()

	if participantTable.hasSeeds then
		participantTable._createSeedList = AoEParticipantTable._createSeedList
		participantTable._createTitle = AoEParticipantTable._createTitle
		participantTable.create = AoEParticipantTable._createSeedTable
	end

	return participantTable:create()
end

---@param sectionArgs table
---@param key string|number
---@param index number
---@param config ParticipantTableConfig
---@return AoEParticipantTableEntry
function AoEParticipantTable:readEntry(sectionArgs, key, index, config)
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
		seed = valueFromArgs('seed'),
	}

	assert(Opponent.isType(opponentArgs.type), 'Invalid opponent type for "' .. sectionArgs[key] .. '"')

	local opponent = Opponent.readOpponentArgs(opponentArgs)

	if config.sortPlayers and opponent.players then
		table.sort(opponent.players, function (player1, player2)
			local name1 = (player1.displayName or player1.pageName):lower()
			local name2 = (player2.displayName or player2.pageName):lower()
			return name1 < name2
		end)
	end

	if tonumber(opponentArgs.seed) then
		self.hasSeeds = true
	end

	return {
		dq = Logic.readBool(opponentArgs.dq),
		note = opponentArgs.note,
		opponent = opponent,
		inputIndex = index,
		seed = tonumber(opponentArgs.seed)
	}
end

---@return Html?
function AoEParticipantTable:_createSeedTable()
	local config = self.config

	if not config.display then return end

	self.display = self:_createTitle(self.config.title or 'Participants', 'Seeding', 1, 2)
	Array.forEach(self.sections, function(section) self:displaySection(section) end)

	return mw.html.create('div')
		:addClass('table-responsive toggle-area toggle-area-1')
		:attr('data-toggle-area', 1)
		:node(self.display)
		:node(self:_createSeedList())
end

---@return Html
function AoEParticipantTable:_createSeedList()
	local width = tostring(50 + (self.config.showTeams and 242 or 186)) .. 'px'
	local display = self:_createTitle('Seeding', self.config.title or 'Participants', 2, 1, width)

	local wrapper = mw.html.create('div')
		:addClass('participantTable-seeding')

	local entries = Array.sortBy(
		Array.filter(Array.flatMap(self.sections, function(section)
			return section.entries
		end), Logic.isNotEmpty),
		Operator.property('seed'),
		function (a, b)
			return a and b and a < b or false
		end
	)

	Array.forEach(entries, function (entry, index)
		wrapper
			:tag('div')
				:addClass('participantTable-seed')
				:wikitext(index)
				:done()
			:node(self:displayEntry(entry))
	end)

	return display:node(wrapper)
end

---@param tabletitle string
---@param buttontitle string
---@param togglearea integer
---@param buttonarea integer
---@param width string?
---@return Html
function AoEParticipantTable:_createTitle(tabletitle, buttontitle, togglearea, buttonarea, width)
	local title = mw.html.create('div')
			:addClass('participantTable')
			:attr('data-toggle-area-content', togglearea)
			:css('max-width', '100%!important')
			:css('width', width or self.config.width)
			:css('vertical-align', 'middle')
			:tag('span')
				:addClass('toggle-area-button btn btn-small btn-primary')
				:attr('data-toggle-area-btn', buttonarea)
				:css('position', 'absolute')
				:wikitext(buttontitle)

	return title:done()
			:tag('div')
				:addClass('participantTable-title')
				:wikitext(tabletitle)
				:done()
end

return AoEParticipantTable
