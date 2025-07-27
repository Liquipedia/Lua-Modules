---
-- @Liquipedia
-- page=Module:PrizePool/Legacy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local LegacyPrizePool = Lua.import('Module:PrizePool/Legacy')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local SPECIAL_PLACES = {dq = 'dq', dnf = 'dnf', dnp = 'dnp', w = 'w', d = 'd', l = 'l', q = 'q'}

local CustomLegacyPrizePool = {}

local _cache
local TBD = 'TBD'

-- Template entry point
---@return Html
function CustomLegacyPrizePool.run()
	return LegacyPrizePool.run(CustomLegacyPrizePool)
end

---@param newArgs table
---@param CACHED_DATA table
---@param header table
---@return table
function CustomLegacyPrizePool.customHeader(newArgs, CACHED_DATA, header)
	_cache = CACHED_DATA

	newArgs.prizesummary = false

	-- needed in opponent processing
	if header.duo then
		CACHED_DATA.opponentType = Opponent.duo
	elseif header.solo then
		CACHED_DATA.opponentType = Opponent.solo
	else
		CACHED_DATA.opponentType = Opponent.team
	end

	CACHED_DATA.duosCache = {}

	newArgs.type = {type = CACHED_DATA.opponentType}

	return newArgs
end

---@param slot table
---@return number
function CustomLegacyPrizePool.opponentsInSlot(slot)
	local slotInputSize
	if slot.place and not SPECIAL_PLACES[string.lower(slot.place)] then
		local placeRange = mw.text.split(slot.place, '-')
		slotInputSize = tonumber(placeRange[#placeRange]) - tonumber(placeRange[1]) + 1
	end

	local numberOfOpponentsFromInput = 0
	if _cache.opponentType == Opponent.solo then
		numberOfOpponentsFromInput = #slot
	else
		for _, _, opponentIndex in Table.iter.pairsByPrefix(slot, 'team') do
			numberOfOpponentsFromInput = opponentIndex
		end
	end

	return math.max(math.min(slotInputSize or math.huge, numberOfOpponentsFromInput), 1)
end

---@param slot table
---@param newData table
---@param mergeSlots boolean
---@return table[]
function CustomLegacyPrizePool.overwriteMapOpponents(slot, newData, mergeSlots)
	local mapOpponent = function (opponentIndex)
		-- Map Legacy WO flags into score
		if slot['wofrom' .. opponentIndex] then
			slot['lastscore' .. opponentIndex] = 'W'
			slot['lastvsscore' .. opponentIndex] = 'FF'
		elseif slot['woto' .. opponentIndex] then
			slot['lastscore' .. opponentIndex] = 'FF'
			slot['lastvsscore' .. opponentIndex] = 'W'
		end

		local opponentData = CustomLegacyPrizePool._readOpponentArgs{
			slot = slot,
			opponentIndex = opponentIndex,
		}

		local lastVsData
		if _cache.opponentType == Opponent.team or _cache.opponentType == Opponent.solo then
			lastVsData = CustomLegacyPrizePool._readOpponentArgs{
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

		return Table.merge(newData, opponentData)
	end

	local opponents = Array.map(Array.range(1, slot.opponentsInSlot), function(opponentIndex)
		return mapOpponent(opponentIndex) or {} end)

	return opponents
end

---@param props table
---@return table?
function CustomLegacyPrizePool._readOpponentArgs(props)
	local slot = props.slot
	local opponentIndex = props.opponentIndex
	local prefix = props.prefix or ''

	if _cache.opponentType == Opponent.solo then
		local nameInput
		if props.prefix then
			nameInput = slot[prefix .. opponentIndex]
		else
			nameInput = slot[opponentIndex]
		end
		if not nameInput then
			return nil
		end
		nameInput = mw.text.split(nameInput, '|')

		return {
			type = _cache.opponentType,
			[1] = nameInput[#nameInput],
			link = slot[prefix .. 'link' .. opponentIndex] or slot[prefix .. opponentIndex .. 'link'] or nameInput[1],
			flag = slot[prefix .. 'flag' .. opponentIndex] or slot[prefix .. opponentIndex .. 'flag'],
			team = slot[prefix .. 'team' .. opponentIndex] or slot[prefix .. opponentIndex .. 'team'],
			race = slot[prefix .. 'race' .. opponentIndex] or slot[prefix .. opponentIndex .. 'race'],
		}
	elseif _cache.opponentType == Opponent.team then
		return {
			type = _cache.opponentType,
			[1] = slot[prefix .. opponentIndex] or slot['team' .. opponentIndex],
		}
	end

	-- 2v2/duo case
	local opponentData = {type = _cache.opponentType}

	local opponentPrefix = 'team' .. opponentIndex
	for playerIndex = 1, Opponent.partySize(_cache.opponentType) do
		local nameInput = mw.text.split(slot[opponentPrefix .. 'p' .. playerIndex] or TBD, '|')

		opponentData['p' .. playerIndex] = nameInput[#nameInput]
		opponentData['p' .. playerIndex .. 'link'] = slot[opponentPrefix .. 'p' .. playerIndex .. 'link'] or nameInput[1]
		opponentData['p' .. playerIndex .. 'flag'] = slot[opponentPrefix .. 'p' .. playerIndex .. 'flag']
		opponentData['p' .. playerIndex .. 'team'] = slot[opponentPrefix .. 'p' .. playerIndex .. 'team']
		opponentData['p' .. playerIndex .. 'race'] = slot[opponentPrefix .. 'p' .. playerIndex .. 'race']
	end

	if slot['team' .. opponentIndex] then
		_cache.duosCache[slot['team' .. opponentIndex]] = Table.copy(opponentData)
	end

	opponentData.vs = slot['lastvs' .. opponentIndex] -- this is just a ref to a different opponent

	return opponentData
end

---@param newArgs table
---@return table
function CustomLegacyPrizePool.afterSlots(newArgs)
	if _cache.opponentType == Opponent.duo then
		for _, slot in ipairs(newArgs) do
			slot.opponents = Array.map(slot.opponents, CustomLegacyPrizePool._addDuoLastVs)
		end
	end

	return newArgs
end

---@param opponent table
---@return table
function CustomLegacyPrizePool._addDuoLastVs(opponent)
	opponent.lastvs = _cache.duosCache[opponent.vs]
	opponent.vs = nil

	return opponent
end

return CustomLegacyPrizePool
