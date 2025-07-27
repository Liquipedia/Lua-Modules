---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')
local Variables = Lua.import('Module:Variables')

local CustomPrizePool = Lua.import('Module:PrizePool/Custom')
local CustomAwardPrizePool = Lua.import('Module:PrizePool/Award/Custom')
local LegacyPrizePool = Lua.import('Module:PrizePool/Legacy')

local OpponentLibrary = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local StarcraftLegacyPrizePool = {}

local AUTOMATION_START_DATE = '2022-01-14'
local SPECIAL_PLACES = {dq = 'dq', dnf = 'dnf', dnp = 'dnp', w = 'w', d = 'd', l = 'l', q = 'q'}
local BASE_CURRENCY_PRIZE = LegacyPrizePool.BASE_CURRENCY:lower() .. 'prize'

local CACHED_DATA = {
	next = {points = 1, qual = 1, freetext = 1},
	inputToId = {},
	qualifiers = {},
}

---@param frame Frame
---@return Html
function StarcraftLegacyPrizePool.run(frame)
	local args = Template.retrieveReturnValues('PrizePool')
	---@type table
	local header = Array.sub(args, 1, 1)[1]

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

	newArgs.storelpdb = header.storeLpdb
	newArgs.storeTournament = header.storeTournament
	newArgs.series = header.series
	newArgs.tier = header.tier
	newArgs['tournament name'] = header['tournament name']

	-- import settings if not award
	if not Logic.readBool(header.award) then
		newArgs.importLimit = header.importLimit
		header.tournament1 = header.tournament1 or header.tournament
		for key, tournament in Table.iter.pairsByPrefix(header, 'tournament') do
			newArgs[key] = tournament
		end
		header.matchGroupId1 = header.matchGroupId1 or header.matchGroupId
		for key, matchGroupId in Table.iter.pairsByPrefix(header, 'matchGroupId') do
			newArgs[key] = matchGroupId
		end
		if header.lpdb and header.lpdb ~= 'auto' then
			newArgs.import = header.lpdb
		end
		newArgs.import = StarcraftLegacyPrizePool._enableImport(newArgs)
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
		-- while if we import we want to keep them
		if
			not newArgs.import
			and #newArgs[slotIndex].opponents > newArgs[slotIndex].opponentsInSlot
		then
			newArgs[slotIndex].opponents = Array.filter(
				newArgs[slotIndex].opponents,
				function(opponent) return not opponent.isEmpty end
			)
		end

		-- if we import fill up the placements with empty opponents
		if newArgs.import and newArgs[slotIndex].place then
			local slotSize = StarcraftLegacyPrizePool._slotSize(newArgs[slotIndex])
			if #newArgs[slotIndex].opponents < slotSize then
				local startIndex = #newArgs[slotIndex].opponents + 1
				local fillerOpponent = StarcraftLegacyPrizePool._fillerOpponent(newArgs[slotIndex].opponents[startIndex - 1])
				for opponentIndex = startIndex, slotSize do
					newArgs[slotIndex].opponents[opponentIndex] = Table.copy(fillerOpponent)
				end
			end
		end

		Table.mergeInto(newArgs[slotIndex], newArgs[slotIndex].opponents)
		newArgs[slotIndex].opponents = nil
	end

	for _, linkData in pairs(CACHED_DATA.qualifiers) do
		newArgs['qualifies' .. linkData.id] = linkData.link
		newArgs['qualifies' .. linkData.id .. 'name'] = linkData.name
	end

	if CACHED_DATA.plainTextSeedsIndex then
		newArgs['freetext' .. CACHED_DATA.plainTextSeedsIndex] = 'Seed'
	end

	if Logic.readBool(header.award) then
		return CustomAwardPrizePool.run(newArgs)
	end

	return CustomPrizePool.run(newArgs)
end

---@param lastOpponentData table
---@return table
function StarcraftLegacyPrizePool._fillerOpponent(lastOpponentData)
	if lastOpponentData.isEmpty then
		return lastOpponentData
	end

	local fillerOpponent = {}
	for key, item in pairs(lastOpponentData) do
		if not (
			Logic.isNumeric(key)
			or String.contains(key, 'last')
			or String.contains(key, 'flag')
			or String.contains(key, 'race')
			or String.contains(key, 'wdl')
			or String.contains(key, 'team')
			or String.contains(key, 'link')
			or string.match(key, 'p%d')
		) then
			fillerOpponent[key] = item
		end
	end

	return fillerOpponent
end

---@param args table
---@return boolean|string
function StarcraftLegacyPrizePool._enableImport(args)
	local tournamentDate = Variables.varDefault('tournament_enddate',
		Variables.varDefault('tournament_startdate'))
	return Logic.nilOr(
		Logic.readBoolOrNil(args.import),
		args.tournament1,
		args.matchGroupId1,
		not tournamentDate or tournamentDate >= AUTOMATION_START_DATE
	)
end

---@param slot table
---@return table
function StarcraftLegacyPrizePool._mapSlot(slot)
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

	newData.date = slot.date
	newData[BASE_CURRENCY_PRIZE] = (slot[BASE_CURRENCY_PRIZE] and slot[BASE_CURRENCY_PRIZE] ~= '0') and
		slot[BASE_CURRENCY_PRIZE] or nil

	local slotInputSize = math.min(StarcraftLegacyPrizePool._slotSize(slot) or math.huge, #slot)
	local opponentsInSlot = tonumber(slot.count) or math.max(slotInputSize, 1)

	Table.iter.forEachPair(CACHED_DATA.inputToId, function(parameter, newParameter)
		local input = slot[parameter]
		if newParameter == 'seed' then
			StarcraftLegacyPrizePool._handleSeed(newData, input, opponentsInSlot)

		elseif input and tonumber(input) ~= 0 then
			newData[newParameter] = input
		end
	end)

	if newData[BASE_CURRENCY_PRIZE] then
		if newData[BASE_CURRENCY_PRIZE]:match('[^,%.%d]') then
			error('Unexpected value in ' .. newData[BASE_CURRENCY_PRIZE] .. ' for '
				.. (slot.place and ('place=' .. slot.place) or ('award=' .. slot.award)))
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
		award = newData.award,
	}

	for _, item in pairs(SPECIAL_PLACES) do
		newSlot[item] = newData[item]
	end

	return newSlot
end

---@param slot table
---@return number?
function StarcraftLegacyPrizePool._slotSize(slot)
	if not slot.place then
		return
	end

	local placeRange = mw.text.split(slot.place, '-')
	return tonumber(placeRange[#placeRange]) - tonumber(placeRange[1]) + 1
end

---@param storeTo table
---@param input string
---@param slotSize integer
function StarcraftLegacyPrizePool._handleSeed(storeTo, input, slotSize)
	local links = LegacyPrizePool.parseWikiLink(input)

	if Table.isEmpty(links) then
		StarcraftLegacyPrizePool._handlePlainTextSeeds(storeTo, input)
	end

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

---@param storeTo table
---@param input string
function StarcraftLegacyPrizePool._handlePlainTextSeeds(storeTo, input)
	if not input then
		return
	end

	if not CACHED_DATA.plainTextSeedsIndex then
		CACHED_DATA.plainTextSeedsIndex = CACHED_DATA.next.freetext
		CACHED_DATA.next.freetext = CACHED_DATA.plainTextSeedsIndex + 1
	end

	local currentDisplay = storeTo['freetext' .. CACHED_DATA.plainTextSeedsIndex] or ''
	if String.isNotEmpty(currentDisplay) then
		currentDisplay = currentDisplay .. '<br>'
	end
	storeTo['freetext' .. CACHED_DATA.plainTextSeedsIndex] = currentDisplay .. input
end

---@param slot table
---@param newData table
---@param opponentsInSlot integer
---@return table
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

		if slot[BASE_CURRENCY_PRIZE .. opponentIndex] then
			opponentData[BASE_CURRENCY_PRIZE] = slot[BASE_CURRENCY_PRIZE .. opponentIndex]
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

---@param props table
---@return table?
---@return integer
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
			link = slot[prefix .. 'link' .. opponentIndex] or slot[prefix .. opponentIndex .. 'link'] or nameInput[1],
			flag = slot[prefix .. 'flag' .. opponentIndex] or slot[prefix .. opponentIndex .. 'flag'],
			team = slot[prefix .. 'team' .. opponentIndex] or slot[prefix .. opponentIndex .. 'team'],
			race = slot[prefix .. 'race' .. opponentIndex] or slot[prefix .. opponentIndex .. 'race'],
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
			or nameInput[1]
		opponentData['p' .. playerIndex .. 'flag'] = slot[prefix .. 'flag' .. opponentIndex .. 'p' .. playerIndex]
		opponentData['p' .. playerIndex .. 'team'] = slot[prefix .. 'team' .. opponentIndex .. 'p' .. playerIndex]
		opponentData['p' .. playerIndex .. 'race'] = slot[prefix .. 'race' .. opponentIndex .. 'p' .. playerIndex]
	end

	return opponentData, newArgsIndex
end

---@param assignTo table
---@param input string?
---@param slotParam string
function StarcraftLegacyPrizePool._assignType(assignTo, input, slotParam)
	if LegacyPrizePool.isValidPoints(input) then
		local index = CACHED_DATA.next.points
		assignTo['points' .. index] = input
		CACHED_DATA.inputToId[slotParam] = 'points' .. index
		CACHED_DATA.next.points = index + 1

	elseif input and input:lower() == 'seed' then
		CACHED_DATA.inputToId[slotParam] = 'seed'

	elseif String.isNotEmpty(input) then
		---@cast input -nil
		local index = CACHED_DATA.next.freetext
		assignTo['freetext' .. index] = mw.getContentLanguage():ucfirst(input)
		CACHED_DATA.inputToId[slotParam] = 'freetext' .. index
		CACHED_DATA.next.freetext = index + 1
	end
end

---@param opponentData table
---@param param string
---@param value string
function StarcraftLegacyPrizePool._setOpponentReward(opponentData, param, value)
	if param == 'seed' then
		StarcraftLegacyPrizePool._handleSeed(opponentData, value, 1)
	else
		opponentData[param] = value
	end
end

return StarcraftLegacyPrizePool
