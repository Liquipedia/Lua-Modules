---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Currency = require('Module:Currency')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local Page = require('Module:Page')
local Points = mw.loadData('Module:Points/data')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local CustomPrizePool = Lua.import('Module:PrizePool/Custom', {requireDevIfEnabled = true})

local LegacyPrizePool = {}

local SPECIAL_PLACES = {dq = 'dq', dnf = 'dnf', dnp = 'dnp'}
local LETTER_PLACE_TO_NUMBER = {w = 1, d = 1, l = 2}

local CACHED_DATA = {
	next = {points = 1, qual = 1, freetext = 1},
	inputToId = {},
	qualifiers = {},
}

local CHECKMARK = '<div class="fa fa-check green-check"></div>'

local CUSTOM_HANDLER

function LegacyPrizePool.run(dependency)
	local args = Template.retrieveReturnValues('LegacyPrizePool')
	local header = Array.sub(args, 1, 1)[1]
	local slots = Array.sub(args, 2)

	CUSTOM_HANDLER = dependency or {}

	local newArgs = {}

	newArgs.prizesummary = (header.prizeinfo and not header.noprize) and true or false
	newArgs.cutafter = header.cutafter

	if Currency.raw(header.localcurrency) then
		-- If the localcurrency is a valid currency, handle it like currency
		newArgs.localcurrency = header.localcurrency
		CACHED_DATA.inputToId.localprize = 'localprize'
	else
		-- Otherwise handle it like it would been a points input using different parameter
		LegacyPrizePool.assignType(newArgs, header.localcurrency, 'localprize')
	end

	LegacyPrizePool.assignType(newArgs, header.points, 'points')
	LegacyPrizePool.assignType(newArgs, header.points2, 'points2')
	LegacyPrizePool.assignType(newArgs, header.points3, 'points3')

	if header.indiv then
		newArgs.type = {type = Opponent.solo}
	else
		newArgs.type = {type = Opponent.team}
	end

	if CUSTOM_HANDLER.customHeader then
		newArgs = CUSTOM_HANDLER.customHeader(newArgs, CACHED_DATA, header)
	end

	local newSlotIndex = 0
	local currentPlace
	local mergeSlots = Logic.readBool(header.mergeSlots)
	for _, slot in ipairs(slots) do
		-- retrieve the slot and push it into a temp var so it can be altered (to merge slots if need be)
		local tempSlot = LegacyPrizePool.mapSlot(slot, mergeSlots)
		-- if we want to merge slots and the slot we just retrieved
		-- has the same place as the one before, then append the opponents
		if mergeSlots and tempSlot.place and currentPlace == tempSlot.place then
			Array.appendWith(newArgs[newSlotIndex].opponents, unpack(tempSlot.opponents))
		else -- regular case we do not need to merge
			currentPlace = tempSlot.place
			newSlotIndex = newSlotIndex + 1
			newArgs[newSlotIndex] = tempSlot
		end
	end

	-- iterate over slots and merge opponents into the slots directly
	local numberOfSlots = newSlotIndex
	for slotIndex = 1, numberOfSlots do
		Table.mergeInto(newArgs[slotIndex], newArgs[slotIndex].opponents)
		newArgs[slotIndex].opponents = nil
	end

	for link, linkData in pairs(CACHED_DATA.qualifiers) do
		newArgs['qualifies' .. linkData.id] = link
		newArgs['qualifies' .. linkData.id .. 'name'] = linkData.name
	end

	return CustomPrizePool.run(newArgs)
end

function LegacyPrizePool.mapSlot(slot, mergeSlots)
	if not slot.place then
		return {}
	end

	local newData = {}
	if LETTER_PLACE_TO_NUMBER[slot.place:lower()] then
		newData.place = LETTER_PLACE_TO_NUMBER[slot.place:lower()]
	elseif SPECIAL_PLACES[slot.place:lower()] then
		newData[SPECIAL_PLACES[slot.place:lower()]] = true
	else
		newData.place = slot.place
	end

	newData.date = slot.date
	newData.usdprize = (slot.usdprize and slot.usdprize ~= '0') and slot.usdprize or nil

	Table.iter.forEachPair(CACHED_DATA.inputToId, function(parameter, newParameter)
		local input = slot[parameter]
		if newParameter == 'seed' then
			local links = LegacyPrizePool.parseWikiLink(input)
			for _, linkData in ipairs(links) do
				local link = linkData.link

				if not CACHED_DATA.qualifiers[link] then
					CACHED_DATA.qualifiers[link] = {id = CACHED_DATA.next.qual, name = linkData.name}
					CACHED_DATA.next.qual = CACHED_DATA.next.qual + 1
				end

				newData['qualified' .. CACHED_DATA.qualifiers[link].id] = true
			end

		elseif input and input ~= 0 then
			-- Handle the legacy checkmarks, they were set in value = 'q'
			-- If want, in the future this could be parsed as a Qualification instead of a freetext as now
			if input == 'q' then
				input = slot.link and Page.makeInternalLink(CHECKMARK, slot.link) or CHECKMARK
			end

			newData[newParameter] = input
		end
	end)

	if CUSTOM_HANDLER.customSlot then
		newData = CUSTOM_HANDLER.customSlot(newData, CACHED_DATA, slot)
	end

	newData.opponents = LegacyPrizePool.mapOpponents(slot, newData, mergeSlots)

	if mergeSlots then
		return {
			opponents = newData.opponents,
			place = newData.place
		}
	end
	return newData
end

function LegacyPrizePool.mapOpponents(slot, newData, mergeSlots)
	local mapOpponent = function (opponentIndex)
		if not slot[opponentIndex] then
			return
		end

		-- Map Legacy WO flags into score
		if slot['walkoverfrom' .. opponentIndex] or slot['wofrom' .. opponentIndex] then
			slot['lastscore' .. opponentIndex] = 'W'
			slot['lastvsscore' .. opponentIndex] = 'FF'

		elseif slot['walkoverto' .. opponentIndex] or slot['woto' .. opponentIndex] then
			slot['lastscore' .. opponentIndex] = 'FF'
			slot['lastvsscore' .. opponentIndex] = 'W'
		end

		local opponentData = {
			[1] = slot[opponentIndex],
			type = slot['literal' .. opponentIndex] and Opponent.literal or nil,
			date = slot['date' .. opponentIndex],
			link = slot['link' .. opponentIndex],
			wdl = slot['wdl' .. opponentIndex],
			flag = slot['flag' .. opponentIndex],
			team = slot['team' .. opponentIndex],
			lastvs = slot['lastvs' .. opponentIndex],
			lastvsflag = slot['lastvsflag' .. opponentIndex],
			lastvsscore = (slot['lastscore' .. opponentIndex] or '') ..
				'-' ..
				(slot['lastvsscore' .. opponentIndex] or ''),
		}

		if CUSTOM_HANDLER.customOpponent then
			opponentData = CUSTOM_HANDLER.customOpponent(opponentData, CACHED_DATA, slot, opponentIndex)
		end

		if mergeSlots then
			return Table.merge(newData, opponentData)
		end
		return opponentData
	end

	return Array.mapIndexes(mapOpponent)
end

function LegacyPrizePool.assignType(assignTo, input, slotParam)
	if LegacyPrizePool.isValidPoints(input) then
		local index = CACHED_DATA.next.points
		assignTo['points' .. index] = input
		CACHED_DATA.inputToId[slotParam] = 'points' .. index
		CACHED_DATA.next.points = index + 1

	elseif input and input:lower() == 'seed' then
		CACHED_DATA.inputToId[slotParam] = 'seed'

	elseif String.isNotEmpty(input) then
		local index = CACHED_DATA.next.freetext
		assignTo['freetext' .. index] = mw.getContentLanguage():ucfirst(input)
		CACHED_DATA.inputToId[slotParam] = 'freetext' .. index
		CACHED_DATA.next.freetext = index + 1
	end
end

function LegacyPrizePool.isValidPoints(input)
	return Points[input] and true or false
end

function LegacyPrizePool.parseWikiLink(input)
	if not input then
		return {}
	end

	local links = {}

	local inputWithoutHtml = input:gsub('<.->.-</.->', '')

	for inputSection in mw.text.gsplit(inputWithoutHtml, '< *[hb]r */? *>') do
		-- Does this contain a wiki link?
		if string.find(inputSection, '%[') then
			local cleanedInput = inputSection:gsub('^.-%[+', ''):gsub('%].-$', '')
			local link, displayName
			if cleanedInput:find('|') then
				-- Link and Display
				local linkParts = mw.text.split(cleanedInput, '|', true)
				link, displayName = mw.text.trim(linkParts[1]), linkParts[2]

			else
				-- Just link
				link, displayName = cleanedInput, cleanedInput
			end

			if link:sub(1, 1) == '/' then
				-- Relative link
				link = mw.title.getCurrentTitle().fullText .. link
			end
			link = link:gsub(' ', '_')

			table.insert(links, {link = link, name = displayName})
		end
	end

	return links
end

return LegacyPrizePool
