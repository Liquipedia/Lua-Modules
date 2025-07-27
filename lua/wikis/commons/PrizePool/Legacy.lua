---
-- @Liquipedia
-- page=Module:PrizePool/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local Logic = Lua.import('Module:Logic')
local Points = Lua.import('Module:Points/data', {loadData = true})
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local CustomPrizePool = Lua.import('Module:PrizePool/Custom')
local CustomAwardPrizePool = Lua.import('Module:PrizePool/Award/Custom')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local LegacyPrizePool = {}

local SPECIAL_PLACES = {dq = 'dq', dnf = 'dnf', dnp = 'dnp', w = 'w', d = 'd', l = 'l', q = 'q'}

local CACHED_DATA = {
	next = {points = 1, qual = 1, freetext = 1},
	inputToId = {},
	qualifiers = {},
}

local CHECKMARK = '<div class="fa fa-check green-check"></div>'

local CUSTOM_HANDLER

local IS_SOLO = false

LegacyPrizePool.BASE_CURRENCY = 'USD'

---@param dependency table<string, function>?
---@return Html
function LegacyPrizePool.run(dependency)
	local args = Template.retrieveReturnValues('LegacyPrizePool')
	---@type table
	local header = Array.sub(args, 1, 1)[1]
	local slots = Array.sub(args, 2)

	CUSTOM_HANDLER = dependency or {}

	local newArgs = {}

	-- disable import in legacy prize pools
	newArgs.import = false
	-- disable syncPlayers in legacy prize pools
	newArgs.syncPlayers = false

	newArgs.prizesummary = (header.prizeinfo and not header.noprize) and true or false
	newArgs.cutafter = header.cutafter
	newArgs.lpdb_prefix = header.lpdb_prefix
	newArgs.fillPlaceRange = Logic.readBool(header.fillPlaceRange) or false

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

	if header.indiv or (Logic.readBool(header.award) and not Logic.readBool(header.team)) then
		newArgs.type = {type = Opponent.solo}
		IS_SOLO = true
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
		local tempSlot = LegacyPrizePool.mapSlot(slot, mergeSlots, newArgs)
		local place = tempSlot.place or slot.place
		-- if we want to merge slots and the slot we just retrieved
		-- has the same place as the one before, then append the opponents
		if mergeSlots and place and currentPlace == place then
			Array.appendWith(newArgs[newSlotIndex].opponents, unpack(tempSlot.opponents))
		else -- regular case we do not need to merge
			currentPlace = place
			newSlotIndex = newSlotIndex + 1
			newArgs[newSlotIndex] = tempSlot
		end
	end

	if CUSTOM_HANDLER.afterSlots then
		newArgs = CUSTOM_HANDLER.afterSlots(newArgs)
	end

	-- iterate over slots and merge opponents into the slots directly
	local numberOfSlots = newSlotIndex
	for slotIndex = 1, numberOfSlots do
		Table.mergeInto(newArgs[slotIndex], newArgs[slotIndex].opponents)
		newArgs[slotIndex].opponents = nil
	end

	LegacyPrizePool.sortQualifiers(newArgs)

	for _, linkData in pairs(CACHED_DATA.qualifiers) do
		newArgs['qualifies' .. linkData.id] = linkData.link
		newArgs['qualifies' .. linkData.id .. 'name'] = linkData.name
	end

	if Logic.readBool(header.award) then
		return CustomAwardPrizePool.run(newArgs)
	end

	return CustomPrizePool.run(newArgs)
end

---@param args table
function LegacyPrizePool.sortQualifiers(args)
	local qualifiersSortValue = function (qualifier1, qualifier2)
		return qualifier1.occurance == qualifier2.occurance and qualifier1.id < qualifier2.id
			or qualifier1.occurance < qualifier2.occurance
	end

	local qualifiers = Array.extractValues(CACHED_DATA.qualifiers)

	table.sort(qualifiers, qualifiersSortValue)

	local newIndexMap = {}
	Array.forEach(qualifiers, function (qualifier, index)
		newIndexMap[qualifier.id] = index
		qualifier.id = index
	end)

	local moveKeys = function (struct, oldPrefix, newPrefix, indexMap)
		Array.forEach(qualifiers, function (_, index)
			local newIndex = indexMap and indexMap[index] or index
			struct[newPrefix .. newIndex] = struct[oldPrefix .. index]
			struct[oldPrefix .. index] = nil
		end)
	end
	Array.forEach(args, function (slot)
		Array.forEach(slot, function (opponent)
			moveKeys(opponent, 'qualified', 'qualified_temp_')
		end)
		moveKeys(slot, 'qualified', 'qualified_temp_')

		Array.forEach(slot, function (opponent)
			moveKeys(opponent, 'qualified_temp_', 'qualified', newIndexMap)
		end)
		moveKeys(slot, 'qualified_temp_', 'qualified', newIndexMap)
	end)
end

---@param slot table
---@param mergeSlots boolean
---@param headerArgs table
---@return table
function LegacyPrizePool.mapSlot(slot, mergeSlots, headerArgs)
	if not slot.place and not slot.award then
		return {}
	end

	local newData = {}
	if slot.place and SPECIAL_PLACES[slot.place:lower()] then
		newData[SPECIAL_PLACES[slot.place:lower()]] = true
	elseif slot.place then
		newData.place = slot.place
	else
		newData.award = slot.award
	end

	local baseCurrencyPrize = LegacyPrizePool.BASE_CURRENCY:lower() .. 'prize'

	newData.date = slot.date
	newData[baseCurrencyPrize] = (slot[baseCurrencyPrize] and slot[baseCurrencyPrize] ~= '0') and slot[baseCurrencyPrize]
		or nil

	local opponentsInSlot = LegacyPrizePool.opponentsInSlot(slot)
	local needsQualifiedFreetext = false
	Table.iter.forEachPair(CACHED_DATA.inputToId, function(parameter, newParameter)
		local input = slot[parameter]
		if newParameter == 'seed' and input == 'q' then
			if slot.link then
				-- Use qualifier display
				if not slot.link:find('^%[%[') then
					slot.link = '[[' .. slot.link .. ']]'
				end
				LegacyPrizePool.handleSeed(newData, slot.link, opponentsInSlot)
			else
				-- Tracking category
				needsQualifiedFreetext = true
				mw.ext.TeamLiquidIntegration.add_category('Pages with missing qualifier link')
			end
		elseif newParameter == 'seed' then
			LegacyPrizePool.handleSeed(newData, input, opponentsInSlot)
		elseif input and tonumber(input) ~= 0 then
			if input == 'q' then
				input = CHECKMARK
				mw.ext.TeamLiquidIntegration.add_category('Pages with freetext checkmark')
			end

			newData[newParameter] = input
		end
	end)

	if needsQualifiedFreetext then
		local slotParam = 'QUALIFIED_FREETEXT'
		local newParam = CACHED_DATA.inputToId[slotParam]
		if not newParam then
			LegacyPrizePool.assignType(headerArgs, 'Qualification', slotParam)
			newParam = CACHED_DATA.inputToId[slotParam]
		end
		newData[newParam] = CHECKMARK
	end

	if CUSTOM_HANDLER.customSlot then
		newData = CUSTOM_HANDLER.customSlot(newData, CACHED_DATA, slot)
	end

	if CUSTOM_HANDLER.overwriteMapOpponents then
		slot.opponentsInSlot = opponentsInSlot
		newData.opponents = CUSTOM_HANDLER.overwriteMapOpponents(slot, newData, mergeSlots)
	else
		newData.opponents = LegacyPrizePool.mapOpponents(slot, newData, mergeSlots)
	end

	if mergeSlots then
		local newSlot = {
			opponents = newData.opponents,
			place = newData.place,
			award = newData.award,
		}
		for _, item in pairs(SPECIAL_PLACES) do
			newSlot[item] = newData[item]
		end

		return newSlot
	end

	return newData
end

---@param slot table
---@return integer
function LegacyPrizePool.opponentsInSlot(slot)
	if CUSTOM_HANDLER.opponentsInSlot then
		return CUSTOM_HANDLER.opponentsInSlot(slot)
	end

	return #slot
end

---@param storeTo table
---@param input string?
---@param slotSize integer
function LegacyPrizePool.handleSeed(storeTo, input, slotSize)
	local links = LegacyPrizePool.parseWikiLink(input)
	for _, linkData in ipairs(links) do
		local link = linkData.link

		if not CACHED_DATA.qualifiers[link] then
			CACHED_DATA.qualifiers[link] = {id = CACHED_DATA.next.qual, name = linkData.name, link = link, occurance = 0}
			CACHED_DATA.next.qual = CACHED_DATA.next.qual + 1
		end

		CACHED_DATA.qualifiers[link].occurance = CACHED_DATA.qualifiers[link].occurance + slotSize
		storeTo['qualified' .. CACHED_DATA.qualifiers[link].id] = true
	end
end

---@param slot table
---@param newData table
---@param mergeSlots boolean
---@return table[]
function LegacyPrizePool.mapOpponents(slot, newData, mergeSlots)
	local mapOpponent = function (opponentIndex)
		if not slot[opponentIndex] then
			return
		end

		-- Map Legacy WO flags into score
		local walkoverFrom = slot['walkoverfrom' .. opponentIndex] or slot['wofrom' .. opponentIndex]
		local walkoverTo = slot['walkoverto' .. opponentIndex] or slot['woto' .. opponentIndex]
		if walkoverFrom then
			slot['lastscore' .. opponentIndex] = 'W'
			slot['lastvsscore' .. opponentIndex] = 'FF'
			slot['lastvs' .. opponentIndex] = slot['lastvs' .. opponentIndex] or walkoverFrom

		elseif walkoverTo then
			slot['lastscore' .. opponentIndex] = 'FF'
			slot['lastvsscore' .. opponentIndex] = 'W'
			slot['lastvs' .. opponentIndex] = slot['lastvs' .. opponentIndex] or walkoverTo
		end

		local opponentData = {
			[1] = slot[opponentIndex],
			type = slot['literal' .. opponentIndex] and Opponent.literal or nil,
			date = slot['date' .. opponentIndex],
			link = slot['link' .. opponentIndex] or slot['page' .. opponentIndex],
			wdl = slot['wdl' .. opponentIndex],
			flag = slot['flag' .. opponentIndex],
			team = slot['team' .. opponentIndex],
			lastvs = {
				slot['lastvs' .. opponentIndex],
				link = slot['lastvs' .. opponentIndex .. 'link'] or slot['lastvspage' .. opponentIndex],
				flag = slot['lastvsflag' .. opponentIndex],
			},
			lastvsscore = (slot['lastscore' .. opponentIndex] or '') ..
				'-' ..
				(slot['lastvsscore' .. opponentIndex] or ''),
		}

		-- catch empty lastvs table to avoid storing tbd opponents in lastvsdata
		if Table.isEmpty(opponentData.lastvs) then
			opponentData.lastvs = nil
		end

		if not opponentData.link and IS_SOLO then
			local splitPlayer = mw.text.split(opponentData[1], '|')
			opponentData.link = splitPlayer[1]
			opponentData[1] = splitPlayer[#splitPlayer]
		end

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

---@param assignTo table
---@param input string?
---@param slotParam string
function LegacyPrizePool.assignType(assignTo, input, slotParam)
	if LegacyPrizePool.isValidPoints(input) then
		local index = CACHED_DATA.next.points
		assignTo['points' .. index] = input
		CACHED_DATA.inputToId[slotParam] = 'points' .. index
		CACHED_DATA.next.points = index + 1

	elseif input and (input:lower() == 'seed' or input:lower() == 'qualified') then
		CACHED_DATA.inputToId[slotParam] = 'seed'

	elseif String.isNotEmpty(input) then
		---@cast input -nil
		local index = CACHED_DATA.next.freetext
		assignTo['freetext' .. index] = mw.getContentLanguage():ucfirst(input)
		CACHED_DATA.inputToId[slotParam] = 'freetext' .. index
		CACHED_DATA.next.freetext = index + 1
	end
end

---@param input string?
---@return boolean
function LegacyPrizePool.isValidPoints(input)
	return Points[input] and true or false
end

---@param input string?
---@return table
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
				link = cleanedInput
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
