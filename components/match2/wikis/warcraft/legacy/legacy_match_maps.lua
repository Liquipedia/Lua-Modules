---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:LegacyMatchMaps
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--converts the old matchlists to be readable by the match2 system

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Match = require('Module:Match')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Template = require('Module:Template')

local Opponent = require('Module:OpponentLibraries').Opponent

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local NUMBER_OF_OPPONENTS = 2
local MAX_NUM_MAPS = 20
local TBD = 'TBD'
local BYE = 'BYE'

local LegacyMatchMaps = {}

-- invoked by Template:MatchList
---@param frame Frame
---@return string
function LegacyMatchMaps.solo(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	local parsedArgs = {
		id = args.id,
		isLegacy = true,
		title = args.title,
		width = args.width,
		collapsed = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		attached = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		store = not store,
		noDuplicateCheck = store,
	}

	for _, matchInput, matchIndex in Table.iter.pairsByPrefix(args, 'match') do
		parsedArgs['M' .. matchIndex] = LegacyMatchMaps._readSoloMatch(matchInput)
	end

	-- generate Display
	-- this also stores the MatchData
	return MatchGroup.MatchList(parsedArgs)
end

---@param matchInput table
---@return string?
function LegacyMatchMaps._readSoloMatch(matchInput)
	local args = Json.parseIfTable(matchInput)
	if not args then return end

	local details = Json.parseIfTable(args.details) or args.details or {}
	args = Table.merge(details, args)

	if args.date then
		args.dateheader = true
	end

	LegacyMatchMaps._readSoloOpponents(args)
	LegacyMatchMaps._readMaps(args)

	return Match._toEncodedJson(args)
end

---@param args table
function LegacyMatchMaps._readSoloOpponents(args)
	Array.forEach(Array.range(1, NUMBER_OF_OPPONENTS), function(opponentIndex)
		local prefix = 'p' .. opponentIndex
		local name = args[prefix] or TBD
		args[prefix] = nil
		if name:upper() == BYE then
			args['opponent' .. opponentIndex] = {type = Opponent.literal, name = BYE}
			return
		end

		local opponent = {
			type = Opponent.solo,
			p1 = name,
			p1flag = args[prefix .. 'flag'],
			p1link = args[prefix .. 'link'],
			p1race = args[prefix .. 'race'],
			score = args[prefix .. 'score'],
		}

		args[prefix .. 'flag'] = nil
		args[prefix .. 'link'] = nil
		args[prefix .. 'race'] = nil
		args[prefix .. 'score'] = nil

		args['opponent' .. opponentIndex] = opponent
	end)
end

---@param args table
function LegacyMatchMaps._readMaps(args)
	for mapIndex = 1, MAX_NUM_MAPS do
		local prefix = 'map' .. mapIndex
		local map = Table.filterByKey(args, function(key) return String.startsWith(key, prefix) end)
		local map = Table.map(map, function(key, value)
			args[key] = nil
			if key == prefix then
				return 'map', value
			end
			local heroesOpponentIndex = string.match(key, '^' .. prefix .. 'p(%d)heroes$')
			if heroesOpponentIndex then
				return 'heroes' .. heroesOpponentIndex, value
			end
			local raceOpponentIndex = string.match(key, '^' .. prefix .. 'p(%d)race$')
			if raceOpponentIndex then
				return 'race' .. raceOpponentIndex, value
			end

			local newKey = string.gsub(key, '^' .. prefix, '')
			return newKey, value
		end)
		map.vod = args['vodgame' .. mapIndex]
		args['vodgame' .. mapIndex] = nil

		if Table.isNotEmpty(map) then
			args[prefix] = map
		end
	end
end

-- invoked by Template:MatchListStart
---@param frame Frame
function LegacyMatchMaps.teamInit(frame)

end

-- invoked by Template:MatchMapsTeams
---@param frame Frame
function LegacyMatchMaps.teamMatch(frame)

end

-- invoked by Template:MatchListEnd
---@param frame Frame
---@return string
function LegacyMatchMaps.teamClose(frame)

end

return LegacyMatchMaps
