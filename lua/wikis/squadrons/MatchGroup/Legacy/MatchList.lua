---
-- @Liquipedia
-- page=Module:MatchGroup/Legacy/MatchList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Match = Lua.import('Module:Match')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')
local Opponent = Lua.import('Module:Opponent/Custom')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacy = {}

local NUMBER_OF_OPPONENTS = 2

--- for bot conversion to proper match2 matchlists
---@param frame Frame
---@return string
function MatchMapsLegacy.generate(frame)
	local args = Arguments.getArgs(frame)

	local store = Logic.readBoolOrNil(args.store)

	local offset = 0
	local title = args.title
	if not title and not Json.parseIfTable(args[1]) then
		title = args[1]
		offset = 1
	end

	local parsedArgs = {
		id = args.id,
		title = title,
		width = args.width,
		collapsed = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		attached = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		store = store,
		noDuplicateCheck = store == false or nil,
	}

	---@type table[]
	local matches = Array.mapIndexes(function(index)
		return Json.parseIfTable(args[index + offset])
	end)

	Array.forEach(matches, function(match, matchIndex)
		args['M' .. matchIndex] = Match.makeEncodedJson(match)
	end)

	return MatchGroupLegacy.generateWikiCodeForMatchList(parsedArgs)
end

-- invoked by Template:Legacy Match list start
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

-- invoked by Template:Match maps
function MatchMapsLegacy.matchMaps(frame)
	local args = Arguments.getArgs(frame)

	local generate = Logic.readBool(Table.extract(args, 'generate'))

	local processedArgs = Table.copy(args)
	MatchMapsLegacy._handleOpponents(processedArgs)

	-- Template:BracketMatchSummary usage on squadrons only ever contained `|date=` or `|finished=` inputs
	local details = Json.parseIfTable(args.details) or {}
	processedArgs.date = Logic.emptyOr(details.date, processedArgs.date)
	processedArgs.finished = Logic.emptyOr(details.finished, processedArgs.finished)

	if processedArgs.date then
		processedArgs.dateheader = true
	end

	-- all other args from the match maps calls are just passed along directly
	-- as they can be read by the match2 processing

	if generate then
		return Json.stringify(args)
	end

	Template.stashReturnValue(processedArgs, 'LegacyMatchlist')
end

---@param processedArgs table
function MatchMapsLegacy._handleOpponents(processedArgs)
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
