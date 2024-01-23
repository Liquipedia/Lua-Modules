---
-- @Liquipedia
-- wiki=commons
-- page=Module:ManualPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local PlayerDisplay = require('Module:Player/Display')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local Template = require('Module:Template')

local NONBREAKING_SPACE = '&nbsp;'
local TOTAL = 'total'
local QUALIFIED = 'q'
local DID_NOT_QUALIFY = 'dnq'
local DISBANDED = 'disbanded'
local POINTS_TYPES = {
	QUALIFIED,
	DID_NOT_QUALIFY,
	DISBANDED
}

local POINTS_ACTIONS = {
	[QUALIFIED] = function (link)
		return '[[File:GreenCheck.png|Qualified|link=' .. link .. ']]'
	end,
	[DID_NOT_QUALIFY] = function ()
		return Abbreviation.make('DNQ', 'Did not qualify')
	end,
	[DISBANDED] = function ()
		return '[[File:RedCross.png|Disbanded or ineligible]]'
	end
}

---@class ManualPointsTable
---@operator call(table): ManualPointsTable
---@field isSolo boolean
---@field showPlayerTeam boolean
local ManualPointsTable = Class.new(
	function(self)
		self.isSolo = false
		self.showPlayerTeam = false
	end
)
---@param args table
---@return Html
function ManualPointsTable:_makeSubHeader(args)
	local subHeader = mw.html.create('tr')
		:tag('th'):wikitext('#'):done()
		:tag('th'):wikitext(self.isSolo and 'Player' or 'Team'):done()

	if self.isSolo and self.showPlayerTeam then
		subHeader:tag('th'):wikitext('Team')
	end

	Array.mapIndexes(function(index)
		local event = args['event' .. index]
		local eventLink = args['event' .. index .. 'link']
		if String.isNotEmpty(event) then
			subHeader:tag('th')
				:css('min-width:80px')
				:wikitext(String.isNotEmpty(eventLink) and '[['.. eventLink .. '|' .. event .. ']]' or event)
		end

		return event
	end)

	subHeader:tag('th')
		:css('min-width:80px')
		:wikitext('Points')

	return subHeader
end

---@param slot table
---@param points string
---@param suffix string
---@return Html
function ManualPointsTable:_makePointsCell(slot, points, suffix)
	local pointsCell = mw.html.create('td')
		:addClass(Logic.readBool(slot['gold' .. suffix]) and 'gold-text-alt' or nil)
		:addClass(Logic.readBool(slot['active' .. suffix]) and 'bg-active' or nil)
		:css('font-weight', Logic.readBool(slot['gold' .. suffix]) and 'bold' or nil)

	if Table.includes(POINTS_TYPES, points:lower()) then
		pointsCell:wikitext(POINTS_ACTIONS[points:lower()](slot['link' .. suffix] and slot['link' .. suffix] or ''))
	else
		pointsCell:wikitext(suffix == TOTAL and '\'\'\'' .. points .. '\'\'\'' or points)
	end

	return pointsCell
end

---@param slot table
function ManualPointsTable:_makeParticipantCell(slot)
	local participantCell = mw.html.create('td')
		:css('text-align', 'left')

	if self.isSolo then
		participantCell:node(PlayerDisplay.InlinePlayer{player = {
			displayName = slot[1],
			pageName = slot[1],
			flag = slot.flag,
			showLink = true
		}})
	else
		local teamOpponentText = ''
		if String.isNotEmpty(slot.flag) then
			teamOpponentText = teamOpponentText .. Flags.Icon{flag = slot.flag} .. NONBREAKING_SPACE
		end
		teamOpponentText = teamOpponentText .. tostring(Team.team(nil, slot[1]) or '')
		participantCell:wikitext(teamOpponentText)
	end

	return participantCell
end

---@param slot table
---@return Html
function ManualPointsTable:_makeSlotRow(slot)
	local slotRow = mw.html.create('tr')
		:addClass(slot.bg and 'bg-' .. slot.bg or nil)
		:tag('td')
			:addClass(slot.pbg and 'bg-' .. slot.pbg or nil)
			:wikitext(slot.place and '\'\'\'' .. slot.place .. '\'\'\'' or '')
			:done()
		:node(self:_makeParticipantCell(slot))
			:done()

	if self.isSolo and self.showPlayerTeam then
		if String.isNotEmpty(slot.team) then
			slotRow:tag('td')
				:node(Team.icon(nil, slot.team) or nil)
		else
			slotRow:tag('td'):wikitext('')
		end
	end

	for _, points, pointsIndex in Table.iter.pairsByPrefix(slot, 'points') do
		slotRow:node(
			self:_makePointsCell(slot, points, pointsIndex)
		)
	end

	if String.isNotEmpty(slot.total) then
		slotRow:node(
			self:_makePointsCell(slot, slot.total, TOTAL)
		)
	end

	return slotRow
end

-- invoked by Template:Points end
---@return Html
function ManualPointsTable.run()
	local manualPointsTable = ManualPointsTable()
	local args = Template.retrieveReturnValues('ManualPointsTable')
	local header =  Array.sub(args, 1, 1)[1]
	local slots = Array.sub(args, 2)

	manualPointsTable.isSolo = Logic.readBool(header.isSolo)
	manualPointsTable.showPlayerTeam = Logic.readBool(header.teams)

	local wrapper = mw.html.create('table')
		:addClass('table table-bordered wikitable prizepooltable collapsed')
		:css('text-align', 'center')
		:css('margin-top', header.margin or 0)
		:attr('data-cutafter', header.cutafter or 100)

	if String.isNotEmpty(header.title) then
		wrapper:tag('tr'):tag('th')
			:attr('colspan', 100)
			:wikitext(header.title)
	end

	wrapper:node(manualPointsTable:_makeSubHeader(header))

	Array.forEach(slots, function (slot)
		wrapper:node(manualPointsTable:_makeSlotRow(slot))
	end)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(wrapper)
end

return Class.export(ManualPointsTable)
