---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Helper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Template = require('Module:Template')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local DisplayHelper = {}
local _NONBREAKING_SPACE = '&nbsp;'

function DisplayHelper.opponentTypeIsParty(opponentType)
	return opponentType == 'solo'
		or opponentType == 'duo'
		or opponentType == 'trio'
		or opponentType == 'quad'
end

function DisplayHelper.opponentIsTBD(opponent)
	return opponent.type == 'literal'
		or opponent.type == 'team' and opponent.template == 'tbd'
		or opponent.name == 'TBD'

		-- solo/duo/trio/quad opponents are TBD if any of its players are marked TBD
		or (DisplayHelper.opponentTypeIsParty(opponent.type)
			and Array.any(opponent.players, function(player) return player.displayName == 'TBD' end))
end

-- Whether to allow highlighting an opponent via mouseover
function DisplayHelper.opponentIsHighlightable(opponent)
	if opponent.type == 'literal' then
		return opponent.name and opponent.name ~= '' and opponent.name ~= 'TBD' or false
	elseif opponent.type == 'team' then
		return opponent.template and opponent.template ~= 'tbd' or false
	else
		return 0 < #opponent.players
			and Array.all(opponent.players, function(player) return player.pageName ~= '' and player.displayName ~= 'TBD' end)
	end
end

--[[
Builds a hash of the opponent that is used to visually highlight their progress
in the bracket.
]]
function DisplayHelper.makeOpponentHighlightKey(opponent)
	if opponent.type == 'literal' then
		return opponent.name and string.lower(opponent.name) or ''
	elseif opponent.type == 'team' then
		return opponent.template or ''
	else
		return table.concat(Array.map(opponent.players or {}, function(player) return player.pageName or '' end), ',')
	end
end

function DisplayHelper.addOpponentHighlight(node, opponent)
	local canHighlight = DisplayHelper.opponentIsHighlightable(opponent)
	return node
		:addClass(canHighlight and 'brkts-opponent-hover' or nil)
		:attr('aria-label', canHighlight and DisplayHelper.makeOpponentHighlightKey(opponent) or nil)
end

-- Expands a header code by making a RPC call.
function DisplayHelper.expandHeaderCode(headerCode)
	headerCode = headerCode:gsub('$', '!')
	local args = mw.text.split(headerCode, '!')
	local response = mw.message.new('brkts-header-' .. args[2])
		:params(args[3] or '')
		:plain()
	return mw.text.split(response, ',')
end

--[[
Expands a header code or comma demlimited string into an array of header texts
of different lengths. Used for displaying different header texts depending on
the screen width.

Examples:
DisplayHelper.expandHeader('!ux!2') -- returns {'Upper Semi-Finals', 'UB SF'}
DisplayHelper.expandHeader('Qualified,Qual.,Q') -- returns {'Qualified', 'Qual.', 'Q'}
]]
function DisplayHelper.expandHeader(header)
	local isCode = Table.includes({'$', '!'}, header:sub(1, 1))
	return isCode
		and DisplayHelper.expandHeaderCode(header)
		or mw.text.split(header, ',')
end

--[[
Determines whether a match summary popup shall be enabled for a match.

This is the default policy for Bracket and Matchlist. Wikis may specify a
different policy by setting props.matchHasDetails in the Bracket and Matchlist
components.
]]
function DisplayHelper.defaultMatchHasDetails(match)
	return match.dateIsExact or 0 < #match.games
end

-- Display component showing the streams, date, and countdown of a match.
function DisplayHelper.MatchCountdownBlock(match)
	DisplayUtil.assertPropTypes(match, MatchGroupUtil.types.Match.struct)
	local dateFormatString
	if match.dateIsExact == true then
		dateFormatString = 'F j, Y - H:i'
	else
		dateFormatString = 'F j, Y'
	end

	local stream = Table.merge(match.stream, {
		date = mw.getContentLanguage():formatDate(dateFormatString, match.date) .. ' ' .. 
			Template.expandTemplate(mw.getCurrentFrame(), 'abbr/UTC'),
		finished = match.finished and 'true' or nil,
	})
	return mw.html.create('div'):addClass('match-countdown-block')
		:css('text-align', 'center')
		-- Workaround for .brkts-popup-body-element > * selector
		:css('display', 'block')
		:node(require('Module:Countdown')._create(stream))
end

--[[
Displays the map name and link, and the status of the match if it had an
unusual status.
]]
function DisplayHelper.MapAndStatus(game)
	local mapText = game.map
		and ('[[' .. game.map .. ']]')
		or 'Unknown'
	if game.resultType == 'np' or game.resultType == 'default' then
		mapText = '<s>' .. mapText .. '</s>'
	end

	local statusText = nil
	if game.resultType == 'default' then
		if game.walkover == 'L' then
			statusText = _NONBREAKING_SPACE .. '<i>(w/o)</i>'
		elseif game.walkover == 'FF' then
			statusText = _NONBREAKING_SPACE .. '<i>(ff)</i>'
		elseif game.walkover == 'DQ' then
			statusText = _NONBREAKING_SPACE .. '<i>(dq)</i>'
		else
			statusText = _NONBREAKING_SPACE .. '<i>(def.)</i>'
		end
	end

	return mapText .. (statusText or '')
end

--[[
Display component showing the detailed summary of a match. The component will
appear as a popup from the Matchlist and Bracket components. This is a
container component, so it takes in the match ID and bracket ID as inputs,
which it uses to fetch the match data from LPDB and page variables.

This is the default implementation. Specific wikis may override this by passing
in a different props.MatchSummaryContainer in the Bracket and Matchlist
components.
]]
DisplayHelper.DefaultMatchSummaryContainer = function(props)
	local MatchSummaryModule = Lua.import('Module:MatchSummary', {requireDevIfEnabled = true})

	if MatchSummaryModule.getByMatchId then
		return MatchSummaryModule.getByMatchId(props)
	else
		error('DefaultMatchSummaryContainer: Expected MatchSummary.getByMatchId to be a function')
	end
end

--[[
Retrieves the wiki specific global bracket config specified in
MediaWiki:BracketConfig.
]]
DisplayHelper.getGlobalConfig = FnUtil.memoize(function()
	local defaultConfig = {
		headerHeight = 25,
		headerMargin = 8,
		lineWidth = 2,
		matchHeight = 44, -- deprecated
		matchWidth = 150,
		matchWidthMobile = 90,
		opponentHeight = 23,
		roundHorizontalMargin = 20,
		scoreWidth = 20,
	}
	local rawConfig = Json.parse(tostring(mw.message.new('BracketConfig')))
	local config = {}
	for paramName, defaultValue in pairs(defaultConfig) do
		config[paramName] = tonumber(rawConfig[paramName]) or defaultValue
	end
	return config
end)

return DisplayHelper
