---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/MatchList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
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

local LegacyMatchList = {}

local NUMBER_OF_OPPONENTS = 2

-- invoked by Template:Legacy Match list start
---@param frame Frame
function LegacyMatchList.init(frame)
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

-- invoked by Template:Match maps
---@param frame Frame
function LegacyMatchList.matchMaps(frame)
	local args = Arguments.getArgs(frame)

	local processedArgs = Table.copy(args)
	LegacyMatchList._handleOpponents(processedArgs)

	if processedArgs.date then
		processedArgs.dateheader = true
	end

	LegacyMatchList._handleDetails(processedArgs)

	-- all other args from the match maps calls are just passed along directly
	-- as they can be read by the match2 processing

	Template.stashReturnValue(processedArgs, 'LegacyMatchlist')
end

---@param args table
function LegacyMatchList._handleDetails(args)
	local details = Json.parseIfTable(Table.extract(args, 'details'))
	if Logic.isEmpty(details) then return end
	---@cast details -nil

	for prefix, _, mapIndex in Table.iter.pairsByPrefix(details, 'map') do
		args[prefix] = LegacyMatchList._handleMap(details, mapIndex)
	end

	-- merge the remaining details into args
	Table.mergeInto(args, details)
end

---@param details table
---@param mapIndex integer
---@return table
function LegacyMatchList._handleMap(details, mapIndex)
	local prefix = 'map' .. mapIndex
	return {
		map = Table.extract(details, prefix),
		winner = Table.extract(details, prefix .. 'win'),
		vod = Table.extract(details, 'vodgame' .. mapIndex),
	}
end

---@param processedArgs table
function LegacyMatchList._handleOpponents(processedArgs)
	for opponentIndex = 1, NUMBER_OF_OPPONENTS do
		if processedArgs['team' .. opponentIndex] and processedArgs['team' .. opponentIndex]:lower() == 'bye' then
			processedArgs['opponent' .. opponentIndex] = {
				['type'] = Opponent.literal,
				name = 'BYE',
			}
		else
			processedArgs['opponent' .. opponentIndex] = {
				['type'] = Opponent.team,
				template = processedArgs['team' .. opponentIndex],
				score = processedArgs['games' .. opponentIndex],
			}
			if processedArgs['team' .. opponentIndex] == '' then
				processedArgs['opponent' .. opponentIndex]['type'] = 'literal'
			end
		end

		processedArgs['team' .. opponentIndex] = nil
		processedArgs['games' .. opponentIndex] = nil
	end
end

-- invoked by Template:Match list end
---@return string
function LegacyMatchList.close()
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

	LegacyMatchList._resetVars()

	return matchHtml
end

function LegacyMatchList._resetVars()
	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('hide')
	matchlistVars:delete('width')
end

return LegacyMatchList
