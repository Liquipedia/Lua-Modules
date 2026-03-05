---
-- @Liquipedia
-- page=Module:ParticipantTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local ParticipantTable = Lua.import('Module:ParticipantTable/Base')

---@class AoEParticipantTableEntry: ParticipantTableEntry
---@field seed integer?

---@class AoEParticipantTableSection: ParticipantTableSection
---@field entries AoEParticipantTableEntry[]

---@class AoEParticipantTable: ParticipantTable
---@operator call(Frame): AoEParticipantTable
---@field hasSeeds boolean
---@field sections AoEParticipantTableSection[]
local AoEParticipantTable = Class.new(ParticipantTable)

---@param frame Frame
---@return Html?
function AoEParticipantTable.run(frame)
	return AoEParticipantTable(frame):read():store():create()
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

	local entry = ParticipantTable.readEntry(self, sectionArgs, key, index, config) --[[ @as AoEParticipantTableEntry ]]

	local seed = (Json.parseIfTable(sectionArgs[key]) or {}).seed or valueFromArgs('seed')

	if Logic.isNumeric(seed) then
		entry.seed = tonumber(seed)
		self.hasSeeds = true
	end

	return entry
end

---@return Html?
function AoEParticipantTable:create()
	if self.hasSeeds then
		return self:_createSeedTable()
	end
	return ParticipantTable.create(self)
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

	Array.forEach(entries, function (entry)
		wrapper
			:tag('div')
				:addClass('participantTable-seed')
				:wikitext(entry.seed)
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
