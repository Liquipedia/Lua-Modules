---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:MatchGroup/Legacy/MatchList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Match = require('Module:Match')
local MatchGroup = require('Module:MatchGroup')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')
local Template = require('Module:Template')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacy = {}

local NUMBER_OF_OPPONENTS = 2

-- invoked by Template:Legacy Match list start
---@param frame Frame
function MatchMapsLegacy.init(frame)
	local args = Arguments.getArgs(frame)
	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	matchlistVars:set('store', tostring(store))
	matchlistVars:set('bracketid', args.id)
	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width)
	matchlistVars:set('hide', args.hide or 'true')
end

-- invoked by Template:MatchMaps
---@param frame Frame
function MatchMapsLegacy.matchMaps(frame)
	local args = Arguments.getArgs(frame)

	local processedArgs = Table.copy(args)
	MatchMapsLegacy._handleOpponents(processedArgs)

	if processedArgs.date then
		processedArgs.dateheader = true
	end

	local details = Json.parseIfTable(args.details) or {}
	processedArgs.date = Logic.emptyOr(details.date, processedArgs.date)
	processedArgs.finished = Logic.emptyOr(details.finished, processedArgs.finished)

	Table.deepMergeInto(processedArgs, MatchMapsLegacy.handleMaps(processedArgs), details)

	Template.stashReturnValue(processedArgs, 'LegacyMatchlist')
end

---@param processedArgs table
---@return table
function MatchMapsLegacy.handleMaps(processedArgs)
	local maps = Array.mapIndexes(function(mapIndex)
		return Logic.nilIfEmpty{winner = Table.extract(processedArgs, 'map' .. mapIndex .. 'win')}
	end)

	return Table.map(maps, function(mapIndex, map)
		return 'map' .. mapIndex, map
	end)
end

---@param processedArgs table
function MatchMapsLegacy._handleOpponents(processedArgs)
	for opponentIndex = 1, NUMBER_OF_OPPONENTS do
		if processedArgs['player' .. opponentIndex] and processedArgs['player' .. opponentIndex]:lower() == 'bye' then
			processedArgs['opponent' .. opponentIndex] = {
				['type'] = Opponent.literal,
				name = 'BYE',
			}
		else
			processedArgs['opponent' .. opponentIndex] = {
				['type'] = Opponent.solo,
				processedArgs['player' .. opponentIndex],
				flag = processedArgs['player' .. opponentIndex .. 'flag'],
			}
			if processedArgs['player' .. opponentIndex] == '' then
				processedArgs['opponent' .. opponentIndex]['type'] = 'literal'
			end
		end

		processedArgs['player' .. opponentIndex] = nil
	end
end

-- invoked by Template:Match list end
---@return string
function MatchMapsLegacy.close()
	local matches = Template.retrieveReturnValues('LegacyMatchlist') --[[@as table]]

	for matchIndex, match in ipairs(matches) do
		matches['M' .. matchIndex] = Match.makeEncodedJson(match)
		matches[matchIndex] = nil
	end

	matches.id = matchlistVars:get('bracketid')
	matches.isLegacy = true
	matches.title = matchlistVars:get('matchListTitle')
	matches.width = matchlistVars:get('width')
	if matchlistVars:get('hide') == 'true' then
		matches.collapsed = true
		matches.attached = true
	else
		matches.collapsed = false
	end
	if Logic.readBool(matchlistVars:get('store')) then
		matches.store = true
	else
		matches.noDuplicateCheck = true
		matches.store = false
	end

	-- generate Display
	-- this also stores the MatchData
	local matchHtml = MatchGroup.MatchList(matches)

	MatchMapsLegacy._resetVars()

	return matchHtml
end

function MatchMapsLegacy._resetVars()
	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('hide')
	matchlistVars:delete('width')
end

return MatchMapsLegacy
