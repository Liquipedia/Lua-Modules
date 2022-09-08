---
-- @Liquipedia
-- wiki=commons
-- page=Module:PrizePool/Legacy/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Currency = require('Module:Currency')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local CustomPrizePool = Lua.import('Module:PrizePool/Custom', {requireDevIfEnabled = true})
local LegacyPrizePool = Lua.import('Module:PrizePool/Legacy', {requireDevIfEnabled = true})
local OldStarcraftPrizePool = Lua.import('Module:PrizePool/Starcraft/next', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local StarcraftLegacyPrizePool = {}

local SPECIAL_PLACES = {dq = 'dq', dnf = 'dnf', dnp = 'dnp', w = 'w', d = 'd', l = 'l', q = 'q'}
local IMPORT_DEFAULT_ENABLE_START = '2022-01-14'

local CACHED_DATA = {
	next = {points = 1, qual = 1, freetext = 1},
	inputToId = {},
	qualifiers = {},
}

function StarcraftLegacyPrizePool.run(frame)
	local args = Template.retrieveReturnValues('PrizePool')
	local header = Array.sub(args, 1, 1)[1]

	if Logic.readBool(header.award) then
		OldStarcraftPrizePool.TemplatePrizePoolEnd()
	end

	local slots = Array.sub(args, 2)

	local newArgs = {}

	newArgs.prizesummary = false
	newArgs.cutafter = header.cutafter
	newArgs.lpdb_prefix = header.lpdb_prefix

	if Currency.raw(header.localcurrency) then
		-- If the localcurrency is a valid currency, handle it like currency
		newArgs.localcurrency = header.localcurrency
		CACHED_DATA.inputToId.localprize = 'localprize'
	else
		-- Otherwise handle it like it would been a points input using different parameter
		StarcraftLegacyPrizePool._assignType(newArgs, header.localcurrency, 'localprize')
	end

	StarcraftLegacyPrizePool._assignType(newArgs, header.points, 'points')
	StarcraftLegacyPrizePool._assignType(newArgs, header['2points'] or header.points2, 'points2')

	local defaultOpponentType = Opponent.readType(header.opponentType or Opponent.solo)
	if defaultOpponentType then
		newArgs.type = {type = defaultOpponentType}
	end
	assert(newArgs.type, 'Invalid opponentType set.')
	newArgs.type.isarchon = header.defaultIsArchon

	CACHED_DATA.defaultOpponentType = defaultOpponentType
	CACHED_DATA.defaultIsArchon = header.defaultIsArchon

	newArgs.storesmw = header.storeSmw or header['smw mute']
	newArgs.storelpdb = header.storeLpdb
	newArgs.storeTournament = header.storeTournament
	newArgs.series = header.series
	newArgs.tier = header.tier
	newArgs['tournament name'] = header['tournament name']

	-- import settings
	if header.lpdb and header.lpdb ~= 'auto' then
		newArgs.import = header.lpdb
	end
	newArgs.importDefaultEnableStart = header.importDefaultEnableStart
		or IMPORT_DEFAULT_ENABLE_START
	newArgs.importLimit = header.importLimit
	newArgs.tournament1 = header.tournament1 or header.tournament1
	for key, tournament in Table.iter.pairsByPrefix(header, 'tournament') do
		newArgs[key] = tournament
	end
	newArgs.matchGroupId1 = header.matchGroupId1 or header.matchGroupId
	for key, matchGroupId in Table.iter.pairsByPrefix(header, 'matchGroupId') do
		newArgs[key] = matchGroupId
	end

	local newSlotIndex = 0
	local currentPlace
	for _, slot in ipairs(slots) do
		-- retrieve the slot and push it into a temp var so it can be altered (to merge slots if need be)
		local tempSlot = StarcraftLegacyPrizePool._mapSlot(slot)
		local place = tempSlot.place or slot.place
		-- if we want to merge slots and the slot we just retrieved
		-- has the same place as the one before, then append the opponents
		if place and currentPlace == place then
			Array.appendWith(newArgs[newSlotIndex].opponents, unpack(tempSlot.opponents))
		else -- regular case we do not need to merge
			currentPlace = place
			newSlotIndex = newSlotIndex + 1
			newArgs[newSlotIndex] = tempSlot
		end
	end

	-- iterate over slots and merge opponents into the slots directly
	local numberOfSlots = newSlotIndex
	for slotIndex = 1, numberOfSlots do
		-- if we have to merge we need to kick empty opponents
		-- while if we import we want tom keep them
		if
			not StarcraftLegacyPrizePool._enableImport(newArgs)
			and #newArgs[slotIndex].opponents > newArgs[slotIndex].opponentsInSlot
		then
			newArgs[slotIndex].opponents = Array.filter(
				newArgs[slotIndex].opponents,
				function(opponent) return not opponent.isEmpty end
			)
		end
		Table.mergeInto(newArgs[slotIndex], newArgs[slotIndex].opponents)
		newArgs[slotIndex].opponents = nil
	end

	StarcraftLegacyPrizePool._sortQualifiers(newArgs)

	for _, linkData in pairs(CACHED_DATA.qualifiers) do
		newArgs['qualifies' .. linkData.id] = linkData.link
		newArgs['qualifies' .. linkData.id .. 'name'] = linkData.name
	end

	return CustomPrizePool.run(newArgs)
end

function StarcraftLegacyPrizePool._enableImport(args)
	local tournamentEndDate = Variables.varDefault('tournament_enddate',
		Variables.varDefault('tournament_startdate'))
	return Logic.nilOr(
		Logic.readBoolOrNil(args.input),
		args.tournament1,
		args.matchGroupId1,
		not tournamentEndDate or tournamentEndDate >= args.importDefaultEnableStart
	)
end

function StarcraftLegacyPrizePool._sortQualifiers(args)
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

function StarcraftLegacyPrizePool._mapSlot(slot)
	if not slot.place then
		return {}
	end

	local newData = {}
	if SPECIAL_PLACES[slot.place:lower()] then
		newData[SPECIAL_PLACES[slot.place:lower()]] = true
	else
		newData.place = slot.place
	end

	newData.date = slot.date
	newData.usdprize = (slot.usdprize and slot.usdprize ~= '0') and slot.usdprize or nil

	local opponentsInSlot = tonumber(slot.count)
	if not opponentsInSlot and newData.place then
		local placeRange = mw.text.split(newData.place, '-')
		opponentsInSlot = tonumber(placeRange[#placeRange]) - tonumber(placeRange[1]) + 1
	end
	opponentsInSlot = opponentsInSlot or #slot

	Table.iter.forEachPair(CACHED_DATA.inputToId, function(parameter, newParameter)
		local input = slot[parameter]
		if newParameter == 'seed' then
			StarcraftLegacyPrizePool._handleSeed(newData, input, opponentsInSlot)

		elseif input and tonumber(input) ~= 0 then
			newData[newParameter] = input
		end
	end)

	if newData.usdprize then
		if newData.usdprize:match('[^,%.%d]') then
			error('Unexpected value in usdprize for place=' .. slot.place)
		end
	end

	local opponents = StarcraftLegacyPrizePool._mapOpponents(slot, newData, opponentsInSlot)

	if Logic.isNumeric(slot.count) then
		for opponentIndex = 1, tonumber(slot.count) do
			opponents[opponentIndex] = opponents[opponentIndex] or {}
		end
	end

	local newSlot = {
		opponents = opponents,
		opponentsInSlot = opponentsInSlot,
		place = newData.place,
	}

	for _, item in pairs(SPECIAL_PLACES) do
		newSlot[item] = newData[item]
	end

	return newSlot
end

function StarcraftLegacyPrizePool._handleSeed(storeTo, input, slotSize)
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

function StarcraftLegacyPrizePool._mapOpponents(slot, newData, opponentsInSlot)
	local argsIndex = 1

	local mapOpponent = function (opponentIndex)
		-- Map Legacy WO flags into score
		if slot['walkoverfrom' .. opponentIndex] or slot['wofrom' .. opponentIndex] then
			slot['lastscore' .. opponentIndex] = 'W'
			slot['lastvsscore' .. opponentIndex] = 'FF'
		elseif slot['walkoverto' .. opponentIndex] or slot['woto' .. opponentIndex] then
			slot['lastscore' .. opponentIndex] = 'FF'
			slot['lastvsscore' .. opponentIndex] = 'W'
		end

		local opponentData = Json.parseIfTable(slot[opponentIndex])
		if not opponentData then
			opponentData, argsIndex = StarcraftLegacyPrizePool._readOpponentArgs{
				slot = slot,
				opponentIndex = opponentIndex,
				argsIndex = argsIndex,
			}
		end
		argsIndex = argsIndex + 1

		local lastVsData = Json.parseIfTable((opponentData or {}).lastvs or slot[opponentIndex])
		if not lastVsData then
			lastVsData = StarcraftLegacyPrizePool._readOpponentArgs{
				slot = slot,
				opponentIndex = opponentIndex,
				prefix = 'lastvs',
			}
		end

		opponentData = opponentData or {}
		local score
		if slot['lastscore' .. opponentIndex] or slot['lastvsscore' .. opponentIndex] then
			score = (slot['lastscore' .. opponentIndex] or '') ..
					'-' .. (slot['lastvsscore' .. opponentIndex] or '')
		end

		Table.mergeInto(
			opponentData,
			{
				date = slot['date' .. opponentIndex],
				wdl = slot['wdl' .. opponentIndex],
				lastvs = lastVsData,
				lastvsscore = score
			}
		)

		if slot['points' .. opponentIndex] then
			local param = CACHED_DATA.inputToId['points']
			StarcraftLegacyPrizePool._setOpponentReward(opponentData, param, slot['points' .. opponentIndex])
		end

		local points2 = slot['2points' .. opponentIndex] or slot['2points']
		if points2 then
			local param = CACHED_DATA.inputToId['points2']
			StarcraftLegacyPrizePool._setOpponentReward(opponentData, param, points2)
		end

		if slot['usdprize' .. opponentIndex] then
			opponentData.usdprize = slot['usdprize' .. opponentIndex]
		end

		if slot['localprize' .. opponentIndex] then
			local param = CACHED_DATA.inputToId['localprize']
			StarcraftLegacyPrizePool._setOpponentReward(opponentData, param, slot['localprize' .. opponentIndex])
		end

		if Table.isEmpty(opponentData) then
			opponentData.isEmpty = true
		end

		return Table.merge(newData, opponentData)
	end

	local opponents = {}
	for opponentIndex = 1, opponentsInSlot do
		table.insert(opponents, mapOpponent(opponentIndex) or {})
	end

	return opponents
end

function StarcraftLegacyPrizePool._readOpponentArgs(props)
	local slot = props.slot
	local opponentIndex = props.opponentIndex
	local argsIndex = props.argsIndex or 0
	local prefix = props.prefix or ''

	if CACHED_DATA.defaultOpponentType == Opponent.team
		or CACHED_DATA.defaultOpponentType == Opponent.solo
		or CACHED_DATA.defaultOpponentType == Opponent.literal then

		local nameInput
		if props.prefix then
			nameInput = slot[prefix .. opponentIndex]
		else
			nameInput = slot[argsIndex]
		end
		if not nameInput then
			return nil, argsIndex
		end
		nameInput = mw.text.split(nameInput, '|')
		return {
			type = CACHED_DATA.defaultOpponentType,
			isarchon = CACHED_DATA.defaultIsArchon,
			[1] = nameInput[#nameInput],
			link = slot[prefix .. 'link' .. opponentIndex] or nameInput[1],
			flag = slot[prefix .. 'flag' .. opponentIndex],
			team = slot[prefix .. 'team' .. opponentIndex],
			race = slot[prefix .. 'race' .. opponentIndex],
		}, argsIndex
	end

	local defaultPartySize = Opponent.partySize(CACHED_DATA.defaultOpponentType)
	local newArgsIndex = argsIndex + defaultPartySize - 1

	local opponentData = {
		type = CACHED_DATA.defaultOpponentType,
		isarchon = CACHED_DATA.defaultIsArchon,
	}
	for playerIndex = 1, defaultPartySize do
		local nameInput
		if props.prefix then
			nameInput = slot[prefix .. opponentIndex .. 'p' .. playerIndex]
		else
			nameInput = slot[argsIndex]
			argsIndex = argsIndex + 1
		end
		if not nameInput then
			return nil, newArgsIndex
		end
		nameInput = mw.text.split(nameInput, '|')

		opponentData['p' .. playerIndex] = nameInput[#nameInput]
		opponentData['p' .. playerIndex .. 'link'] = slot[prefix .. 'link' .. opponentIndex .. 'p' .. playerIndex]
			or nameInput[#nameInput]
		opponentData['p' .. playerIndex .. 'flag'] = slot[prefix .. 'flag' .. opponentIndex .. 'p' .. playerIndex]
		opponentData['p' .. playerIndex .. 'team'] = slot[prefix .. 'team' .. opponentIndex .. 'p' .. playerIndex]
		opponentData['p' .. playerIndex .. 'race'] = slot[prefix .. 'race' .. opponentIndex .. 'p' .. playerIndex]
	end

	return opponentData, newArgsIndex
end

function StarcraftLegacyPrizePool._assignType(assignTo, input, slotParam)
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

function StarcraftLegacyPrizePool._setOpponentReward(opponentData, param, value)
	if param == 'seed' then
		StarcraftLegacyPrizePool._handleSeed(opponentData, value, 1)
	else
		opponentData[param] = value
	end
end

return StarcraftLegacyPrizePool
