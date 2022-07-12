---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:PrizePool/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Currency = require('Module:LocalCurrency')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Points = mw.loadData('Module:Points/data')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local CustomPrizePool = Lua.import('Module:PrizePool/Custom', {requireDevIfEnabled = true})

local LegacyPrizePool = {}
local nextPoints, nextQual, nextFreetext = 1, 1, 1
local inputToId = {}
local qualCache = {}

-- Template entry point
function LegacyPrizePool.run()
	local args = Template.retrieveReturnValues('LegacyPrizePool')
	local header = Array.sub(args, 1, 1)[1]
	local slots = Array.sub(args, 2)

	local newArgs = {}

	newArgs.prizesummary = (header.prizeinfo and not header.noprize) and true or false
	newArgs.cutafter = header.cutafter

	if Currency.raw(header.localcurrency) then
		newArgs.localcurrency = header.localcurrency
		inputToId.localprize = 'localprize'
	else
		LegacyPrizePool._assignType(newArgs, header, 'localcurrency')
	end

	LegacyPrizePool._assignType(newArgs, header, 'points')
	LegacyPrizePool._assignType(newArgs, header, 'points2')
	LegacyPrizePool._assignType(newArgs, header, 'points3')

	if args.indiv then
		newArgs.type = {type = 'solo'}
	else
		newArgs.type = {type = 'team'}
	end

	mw.logObject(inputToId)
	for slotIndex, slot in ipairs(slots) do
		newArgs[slotIndex] = LegacyPrizePool._mapSlot(slot)
	end
	for link, idx in pairs(qualCache) do
		newArgs['qualifies' .. idx] = link
	end
	mw.logObject(newArgs)

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

	Table.iter.forEachPair(inputToId, function(parameter, newParameter)
		if parameter == 'localcurrency' then
			parameter = 'localprize'
		end
		local input = slot[parameter]
		if newParameter == 'seed' then
			local links = LegacyPrizePool._parseWikiLink(input)
			for _, link in ipairs(links) do
				if not qualCache[link] then
					qualCache[link] = nextQual
					nextQual = nextQual + 1
				end
				newData['qualified' .. qualCache[link]] = true
			end
		elseif input and input ~= 0 then
			newData[newParameter] = input
		end
	end)

	for opponentIndex = 1, 128 do
		if not slot[opponentIndex] then
			break
		end

		local newOpponent = {}
		newOpponent[1] = slot[opponentIndex]
		newOpponent.date = slot['date' .. opponentIndex]
		newOpponent.wdl = slot['wdl' .. opponentIndex]
		newOpponent.lastvs = slot['lastvs' .. opponentIndex]
		newOpponent.lastscore = slot['lastscore' .. opponentIndex]
		newOpponent.lastvsscore = slot['lastvsscore' .. opponentIndex]

		newData[opponentIndex] = Json.stringify(newOpponent)
	end

	return newData
end

function LegacyPrizePool._assignType(assignTo, args, parameter)
	local input = args[parameter]
	if LegacyPrizePool._isValidPoints(input) then
		assignTo['points' .. nextPoints] = input
		inputToId[parameter] = 'points' .. nextPoints
		nextPoints = nextPoints + 1
	elseif input == 'seed' then
		inputToId[parameter] = 'seed'
	elseif String.isNotEmpty(input) then
		assignTo['freetext' .. nextFreetext] = mw.getContentLanguage():ucfirst(input)
		inputToId[parameter] = 'freetext' .. nextFreetext
		nextFreetext = nextFreetext + 1
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
