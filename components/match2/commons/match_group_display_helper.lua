---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Helper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local I18n = require('Module:I18n')
local Info = require('Module:Info')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')

local Opponent = Lua.import('Module:Opponent')

local DisplayHelper = {}
local NONBREAKING_SPACE = '&nbsp;'
local UTC = Timezone.getTimezoneString('UTC')

-- Whether to allow highlighting an opponent via mouseover
---@param opponent standardOpponent
---@return boolean
function DisplayHelper.opponentIsHighlightable(opponent)
	if opponent.type == 'literal' then
		return opponent.name and opponent.name ~= '' and opponent.name ~= 'TBD' or false
	elseif opponent.type == 'team' then
		return opponent.template and opponent.template ~= 'tbd' or false
	else
		return 0 < #opponent.players
			and Array.all(opponent.players, function(player)
				return Logic.isNotEmpty(player.pageName) and Logic.isNotEmpty(player.displayName) and player.displayName ~= 'TBD'
			end)
	end
end

---@param node Html
---@param opponent standardOpponent
---@return Html
function DisplayHelper.addOpponentHighlight(node, opponent)
	local canHighlight = DisplayHelper.opponentIsHighlightable(opponent)
	return node
		:addClass(canHighlight and 'brkts-opponent-hover' or nil)
		:attr('aria-label', canHighlight and Opponent.toName(opponent) or nil)
end

-- Expands a header code by making a RPC call.
---@param headerCode string
---@return string[]
function DisplayHelper.expandHeaderCode(headerCode)
	headerCode = headerCode:gsub('$', '!')
	local args = mw.text.split(headerCode, '!')
	local response = I18n.translate('brkts-header-' .. args[2], {round = args[3]})
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
---@param header string
---@return string[]
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
---@param match MatchGroupUtilMatch
---@return boolean
function DisplayHelper.defaultMatchHasDetails(match)
	return match.dateIsExact
		or (match.timestamp and match.timestamp ~= Date.defaultTimestamp)
		or Logic.isNotEmpty(match.vod)
		or not Table.isEmpty(match.links)
		or Logic.isNotEmpty(match.comment)
		or 0 < #match.games
end

-- Display component showing the streams, date, and countdown of a match.
---@param match MatchGroupUtilMatch
---@return Html
function DisplayHelper.MatchCountdownBlock(match)
	local dateString
	if match.dateIsExact == true then
		local timestamp = Date.readTimestamp(match.date) + (Timezone.getOffset(match.extradata.timezoneid) or 0)
		dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
				.. (Timezone.getTimezoneString(match.extradata.timezoneid) or UTC)
	else
		dateString = mw.getContentLanguage():formatDate('F j, Y', match.date)
	end

	local stream = Table.merge(match.stream, {
		date = dateString,
		finished = match.finished and 'true' or nil,
	})
	return mw.html.create('div'):addClass('match-countdown-block')
		:css('text-align', 'center')
		-- Workaround for .brkts-popup-body-element > * selector
		:css('display', 'block')
		:node(require('Module:Countdown')._create(stream))
end

---Displays the map name and link, and the status of the match if it had an unusual status.
---@param game MatchGroupUtilGame
---@param config {noLink: boolean}?
---@return string
function DisplayHelper.MapAndStatus(game, config)
	config = config or {}
	local mapText
	if game.map and game.mapDisplayName then
		mapText = '[[' .. game.map .. '|' .. game.mapDisplayName .. ']]'
	elseif game.map and not config.noLink then
		mapText = '[[' .. game.map .. ']]'
	elseif game.map then
		mapText = game.map
	else
		mapText = 'Unknown'
	end
	if game.resultType == 'np' or game.resultType == 'default' then
		mapText = '<s>' .. mapText .. '</s>'
	end

	local statusText = nil
	if game.resultType == 'default' then
		if game.walkover == 'l' then
			statusText = NONBREAKING_SPACE .. '<i>(w/o)</i>'
		elseif game.walkover == 'ff' then
			statusText = NONBREAKING_SPACE .. '<i>(ff)</i>'
		elseif game.walkover == 'dq' then
			statusText = NONBREAKING_SPACE .. '<i>(dq)</i>'
		else
			statusText = NONBREAKING_SPACE .. '<i>(def.)</i>'
		end
	end

	return mapText .. (statusText or '')
end

---@param score string|number|nil
---@param opponentIndex integer
---@param resultType string?
---@param walkover string?
---@param winner integer?
---@return string
function DisplayHelper.MapScore(score, opponentIndex, resultType, walkover, winner)
	if resultType == 'default' then
		return opponentIndex == winner and 'W' or string.upper(walkover or '')
	end
	return score and tostring(score) or ''
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
---@param props table
---@return Html
function DisplayHelper.DefaultMatchSummaryContainer(props)
	local MatchSummaryModule = Lua.import('Module:MatchSummary')

	assert(MatchSummaryModule.getByMatchId, 'Expected MatchSummary.getByMatchId to be a function')

	return MatchSummaryModule.getByMatchId(props)
end

---@param props table
---@return Html
function DisplayHelper.DefaultMatchPageContainer(props)
	local MatchPageModule = Lua.import('Module:MatchPage')

	assert(MatchPageModule.getByMatchId, 'Expected MatchPage.getByMatchId to be a function')

	return MatchPageModule.getByMatchId(props)
end

---Retrieves the wiki specific global bracket config.
---@return table
DisplayHelper.getGlobalConfig = FnUtil.memoize(function()
	local defaultConfig = {
		forceShortName = false,
		headerHeight = 25,
		headerMargin = 8,
		lineWidth = 2,
		matchWidth = 150,
		matchWidthMobile = 88,
		opponentHeight = 24,
		roundHorizontalMargin = 20,
		scoreWidth = 22,
	}
	local wikiConfig = Info.config.match2
	local config = {}
	for paramName, defaultValue in pairs(defaultConfig) do
		config[paramName] = wikiConfig[paramName] or defaultValue
	end
	return config
end)

return DisplayHelper
