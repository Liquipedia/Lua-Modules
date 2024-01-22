---
-- @Liquipedia
-- wiki=commons
-- page=Module:ManualPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Team = require('Module:Team')
local Template = require('Module:Template')

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

local ManualPointsTable = {}

---@param args table
---@return Html
function ManualPointsTable._makeSubHeader(args)
	local row = mw.html.create('tr')
		:tag('th'):wikitext('#'):done()
		:tag('th'):wikitext('Team'):done()

	Array.mapIndexes(function(index)
		local event = args['event' .. index]
		local eventLink = args['event' .. index .. 'link']
		if String.isNotEmpty(event) then
			row:tag('th')
				:css('min-width:80px')
				:wikitext(String.isNotEmpty(eventLink) and '[['.. eventLink .. '|' .. event .. ']]' or event)
		end

		return event
	end)

	row:tag('th')
		:css('min-width:80px')
		:wikitext('Points')

	return row
end

---@param slot table
---@param points string
---@param suffix string
---@return Html
function ManualPointsTable._makePointsCell(slot, points, suffix)
	local td = mw.html.create('td')
		:addClass(Logic.readBool(slot['gold' .. suffix]) and 'gold-text-alt' or '')
		:addClass(Logic.readBool(slot['active' .. suffix]) and 'bg-active' or '')
		:css('font-weight', Logic.readBool(slot['gold' .. suffix]) and 'bold' or nil)

	if Table.includes(POINTS_TYPES, points) then
		td:wikitext(POINTS_ACTIONS[points](slot['link' .. suffix] and slot['link' .. suffix] or ''))
	else
		td:wikitext(suffix == TOTAL and '\'\'\'' .. points .. '\'\'\'' or points)
	end

	return td
end

---@param slot table
function ManualPointsTable._makeSlot(slot)
	local row = mw.html.create('tr')
		:addClass(slot.bg and 'bg-' .. slot.bg or '')
		:tag('td')
			:addClass(slot.pbg and 'bg-' .. slot.pbg or '')
			:wikitext(slot.place and '\'\'\'' .. slot.place .. '\'\'\'' or '')
			:done()
		:tag('td')
			:css('text-align', 'left')
			:wikitext(slot[1] and Team.team(nil, slot[1]) or '')
			:done()

	for _, points, pointsIndex in Table.iter.pairsByPrefix(slot, 'points') do
		row:node(
			ManualPointsTable._makePointsCell(slot, points, pointsIndex)
		)
	end

	if String.isNotEmpty(slot.total) then
		row:node(
			ManualPointsTable._makePointsCell(slot, slot.total, TOTAL)
		)
	end

	return row
end

-- invoked by Template:Points end
---@return Html
function ManualPointsTable.run()
	local args = Template.retrieveReturnValues('ManualPointsTable')
	local header =  Array.sub(args, 1, 1)[1]
	local slots = Array.sub(args, 2)

	local wrapper = mw.html.create('table')
		:addClass('table table-bordered wikitable prizepooltable collapsed')
		:css('text-align', 'center')
		:css('margin-top', header.margin or 0)
		:attr('data-cutafter', header.cutafter or 100)

	if String.isNotEmpty(header.title) then
		wrapper:tag('tr'):tag('th')
			:css('colspan', 100)
			:wikitext(header.title)
	end

	wrapper:node(ManualPointsTable._makeSubHeader(header))

	Array.forEach(slots, function (slot)
		wrapper:node(ManualPointsTable._makeSlot(slot))
	end)

	return mw.html.create('div')
		:addClass('table-responsive')
		:node(wrapper)
end

return ManualPointsTable
