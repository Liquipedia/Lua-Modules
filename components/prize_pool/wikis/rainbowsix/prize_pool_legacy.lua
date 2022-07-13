---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:PrizePool/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Currency = require('Module:Currency')
local Lua = require('Module:Lua')
local Points = mw.loadData('Module:Points/data')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local CustomPrizePool = Lua.import('Module:PrizePool/Custom', {requireDevIfEnabled = true})

local LegacyPrizePool = {}

local CACHED_DATA = {
	nextPoints = 1,
	nextQual = 1,
	nextFreetext = 1,
	inputToId = {},
	qualifiers = {},
}

-- Template entry point
function LegacyPrizePool.run()
	local args = Template.retrieveReturnValues('LegacyPrizePool')
	local header = Array.sub(args, 1, 1)[1]
	local slots = Array.sub(args, 2)

	local newArgs = {}

	newArgs.prizesummary = (header.prizeinfo and not header.noprize) and true or false
	newArgs.cutafter = header.cutafter

	if Currency.raw(header.localcurrency) then
		-- If the localcurrency is a valid currency, handle it like currency
		newArgs.localcurrency = header.localcurrency
		CACHED_DATA.inputToId.localprize = 'localprize'
	else
		-- Otherwise handle it like it would been a points input using different parameter
		LegacyPrizePool._assignType(newArgs, header.localcurrency, 'localprize')
	end

	LegacyPrizePool._assignType(newArgs, header.points, 'points')
	LegacyPrizePool._assignType(newArgs, header.points2, 'points2')
	LegacyPrizePool._assignType(newArgs, header.points3, 'points3')

	if args.indiv then
		newArgs.type = {type = 'solo'}
	else
		newArgs.type = {type = 'team'}
	end

	for slotIndex, slot in ipairs(slots) do
		newArgs[slotIndex] = LegacyPrizePool._mapSlot(slot)
	end
	for link, idx in pairs(CACHED_DATA.qualifiers) do
		newArgs['qualifies' .. idx] = link
	end

	return CustomPrizePool.run(newArgs)
end

function LegacyPrizePool._mapSlot(slot)
	if not slot.place then
		return {}
	end

	local newData = {}
	if slot.place:lower() == 'dq' or slot.place:lower() == 'dnp' then
		newData[slot.place:lower()] = true
	else
		newData.place = slot.place
	end

	newData.date = slot.date
	newData.usdprize = (slot.usdprize and slot.usdprize ~= '0') and slot.usdprize or nil

	Table.iter.forEachPair(CACHED_DATA.inputToId, function(parameter, newParameter)
		local input = slot[parameter]
		if newParameter == 'seed' then
			local links = LegacyPrizePool._parseWikiLink(input)
			for _, link in ipairs(links) do

				if not CACHED_DATA.qualifiers[link] then
					CACHED_DATA.qualifiers[link] = CACHED_DATA.nextQual
					CACHED_DATA.nextQual = CACHED_DATA.nextQual + 1
				end

				newData['qualified' .. CACHED_DATA.qualifiers[link]] = true
			end

		elseif input and input ~= 0 then
			newData[newParameter] = input
		end
	end)

	Table.mergeInto(newData, LegacyPrizePool._mapOpponents(slot))

	return newData
end

function LegacyPrizePool._mapOpponents(slot)
	local mapOpponent = function (opponentIndex)
		if not slot[opponentIndex] then
			return
		end

		local newOpponent = {}
		newOpponent[1] = slot[opponentIndex]
		newOpponent.date = slot['date' .. opponentIndex]
		newOpponent.link = slot['link' .. opponentIndex]
		newOpponent.wdl = slot['wdl' .. opponentIndex]
		newOpponent.flag = slot['flag' .. opponentIndex]
		newOpponent.team = slot['team' .. opponentIndex]
		newOpponent.lastvs = slot['lastvs' .. opponentIndex]
		newOpponent.lastvsflag = slot['lastvsflag' .. opponentIndex]
		newOpponent.lastscore = slot['lastscore' .. opponentIndex]
		newOpponent.lastvsscore = slot['lastvsscore' .. opponentIndex]

		return newOpponent
	end

	return Array.mapIndexes(mapOpponent)
end

function LegacyPrizePool._assignType(assignTo, input, slotParam)
	if LegacyPrizePool._isValidPoints(input) then
		assignTo['points' .. CACHED_DATA.nextPoints] = input
		CACHED_DATA.inputToId[slotParam] = 'points' .. CACHED_DATA.nextPoints
		CACHED_DATA.nextPoints = CACHED_DATA.nextPoints + 1

	elseif input == 'seed' then
		CACHED_DATA.inputToId[slotParam] = 'seed'

	elseif String.isNotEmpty(input) then
		assignTo['freetext' .. CACHED_DATA.nextFreetext] = mw.getContentLanguage():ucfirst(input)
		CACHED_DATA.inputToId[slotParam] = 'freetext' .. CACHED_DATA.nextFreetext
		CACHED_DATA.nextFreetext = CACHED_DATA.nextFreetext + 1
	end
end

function LegacyPrizePool._isValidPoints(input)
	return Points[input] and true or false
end

function LegacyPrizePool._parseWikiLink(input)
	if not input then
		return {}
	end

	local links = {}

	for inputSection in mw.text.gsplit(input, '<[hb]r/?>') do
		local cleanedInput = inputSection:gsub('%[', ''):gsub('%]', '')
		if cleanedInput:find('|') then
			local linkParts = mw.text.split(cleanedInput, '|', true)
			local link = linkParts[1]

			if link:sub(1, 1) == '/' then
				-- Relative link
				link = mw.title.getCurrentTitle().fullText .. link
			end
			link = link:gsub(' ', '_')

			table.insert(links, link)
		end
	end

	return links
end

return LegacyPrizePool
