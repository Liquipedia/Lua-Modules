---
-- @Liquipedia
-- page=Module:MatchMaps/Legacy/Store
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
	This module is used in the process to convert Legacy match1 MatchLists and SingleMatches into match2.
	It's mostly a wrapper around the matches, handling headers, width, etc.
	It also invokes match2 with the match and map information gathered from
		Module:MatchMaps/Legacy and Module:LegacyBracketMatchSummary.
	It is invoked by Template:LegacyMatchListStart, Template:MatchListEnd & Template:LegacySingleMatch.
]]

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local MatchGroup = Lua.import('Module:MatchGroup')
local MatchGroupLegacy = Lua.import('Module:MatchGroup/Legacy')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Template = Lua.import('Module:Template')

local globalVars = PageVariableNamespace()
local matchlistVars = PageVariableNamespace('LegacyMatchlist')

local MatchMapsLegacyStore = {}

-- Invoked by Template:LegacyMatchListStart & Template:LegacySingleMatch
function MatchMapsLegacyStore.init(frame)
	local args = Arguments.getArgs(frame)
	return MatchMapsLegacyStore._init(args)
end

function MatchMapsLegacyStore._init(args)
	local store = Logic.nilOr(
		Logic.readBoolOrNil(args.store),
		not Logic.readBool(globalVars:get('disable_LPDB_storage'))
	)

	local warnings = {}
	table.insert(warnings, 'This is a legacy matchlist! Please use the new matchlist instead.')

	if store then
		matchlistVars:set('bracketid', args.id)
	end

	matchlistVars:set('matchListTitle', args.title or args[1] or 'Match List')
	matchlistVars:set('width', args.width)
	matchlistVars:set('hide', args.hide or 'true' )
	matchlistVars:set('warnings', Json.stringify(warnings))
	matchlistVars:set('store', store and 'true' or nil)
	matchlistVars:set('gsl', args.gsl)
end

-- Invoked by Template:MatchListEnd
function MatchMapsLegacyStore.close()
	local bracketId = matchlistVars:get('bracketid')
	if not bracketId then
		return '</table>'
	end
	if bracketId == 'abcs' then
		return
	end

	local matches = Template.retrieveReturnValues('LegacyMatchlist')
	local processMatches = {}
	local gsl = matchlistVars:get('gsl')

	for matchIndex, match in ipairs(matches) do
		local header = match.title
		if matchIndex == 1 and (gsl == 'winners' or gsl == 'losers') then
			header = 'Opening Matches'
		elseif (matchIndex == 3 and gsl == 'winners') or (matchIndex == 4 and gsl == 'losers') then
			header = 'Winners Match'
		elseif (matchIndex == 4 and gsl == 'winners') or (matchIndex == 3 and gsl == 'losers') then
			header = 'Elimination Match'
		elseif matchIndex == 5 and (gsl == 'winners' or gsl == 'losers') then
			header = 'Decider Match'
		end

		processMatches['M'..matchIndex..'header'] = header
		processMatches['M'..matchIndex] = Json.stringify(match)
	end
	processMatches.id = bracketId
	processMatches.title = matchlistVars:get('matchListTitle')
	processMatches.width = matchlistVars:get('width')
	if matchlistVars:get('hide') == 'true' then
		processMatches.collapsed = true
		processMatches.attached = true
	else
		processMatches.collapsed = false
	end
	processMatches.isLegacy = true

	-- store match
	local matchHtml = MatchGroup.MatchList(processMatches)

	--local warnings = Json.parseIfString(matchlistVars:get('warnings')) or {}

	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('warnings')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('matchListTitle')
	matchlistVars:delete('hide')
	matchlistVars:delete('width')
	matchlistVars:delete('gsl')

	return matchHtml
end

-- Invoked by LegacySingleMatch (previously Template:Showmatch)
function MatchMapsLegacyStore.closeSingle(frame)
	local args = Arguments.getArgs(frame)
	local bracketId = matchlistVars:get('bracketid')

	local matches = Template.retrieveReturnValues('LegacyMatchlist')
	local processMatches = {}

	for matchIndex, match in ipairs(matches) do
		processMatches['M'..matchIndex] = Json.stringify(match)
	end
	processMatches.id = bracketId or args.id
	processMatches.isLegacy = true
	processMatches.hide = true

	-- store match
	MatchGroup.MatchList(processMatches)

	local MatchGroupBase = Lua.import('Module:MatchGroup/Base')
	-- display match
	local matchHtml = MatchGroup.MatchByMatchId(
		{id = MatchGroupBase.readBracketId(processMatches.id), matchid = '1', width = matchlistVars:get('width')}
	)

	--local warnings = Json.parseIfString(matchlistVars:get('warnings')) or {}

	globalVars:set('match2bracketindex', (globalVars:get('match2bracketindex') or 0) + 1)
	globalVars:set('match_number', 0)
	globalVars:delete('matchsection')
	matchlistVars:delete('warnings')
	matchlistVars:delete('store')
	matchlistVars:delete('bracketid')
	matchlistVars:delete('width')

	return matchHtml
end

--- for bot conversion to proper match2 matchlists
---@param frame Frame
---@return string?
function MatchMapsLegacyStore.generate2(frame)
	local args = Arguments.getArgs(frame)

	local bracketId = args.id
	if bracketId == 'abcs' then
		return
	end

	local store = Logic.readBoolOrNil(args.store)

	local offset = 0
	local title = args.title
	if not title and not Json.parseIfTable(args[1]) then
		title = args[1]
		offset = 1
	end

	local parsedArgs = {
		id = bracketId,
		title = title,
		width = args.width,
		collapsed = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		attached = Logic.nilOr(Logic.readBoolOrNil(args.hide), true),
		store = store,
		noDuplicateCheck = store == false or nil,
		matchsection = Logic.nilOr(args.lpdb_title, args.title),
		patch = args.patch,
	}

	---@type table[]
	local matches = Array.mapIndexes(function(index)
		return Json.parseIfTable(args[index + offset])
	end)

	local gsl = args.gsl

	Array.forEach(matches, function(match, matchIndex)
		local header = match.title
		if matchIndex == 1 and (gsl == 'winners' or gsl == 'losers') then
			header = 'Opening Matches'
		elseif (matchIndex == 3 and gsl == 'winners') or (matchIndex == 4 and gsl == 'losers') then
			header = 'Winners Match'
		elseif (matchIndex == 4 and gsl == 'winners') or (matchIndex == 3 and gsl == 'losers') then
			header = 'Elimination Match'
		elseif matchIndex == 5 and (gsl == 'winners' or gsl == 'losers') then
			header = 'Decider Match'
		end
		parsedArgs['M' .. matchIndex .. 'header'] = header
		parsedArgs['M' .. matchIndex] = Json.stringify(match)
	end)

	return MatchGroupLegacy.generateWikiCodeForMatchList(parsedArgs)
end

return MatchMapsLegacyStore
