---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchGroup/Display/Helper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local FnUtil = require('Module:FnUtil')
local I18n = require('Module:I18n')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayerDisplay = require('Module:Player/Display')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local Timezone = require('Module:Timezone')

local Info = Lua.import('Module:Info', {loadData = true})

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local DisplayHelper = {}
local NONBREAKING_SPACE = '&nbsp;'
local UTC = Timezone.getTimezoneString('UTC')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

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

---Creates comments that describe substitute player(s) of the match.
---@param match table
---@return string[]
function DisplayHelper.createSubstitutesComment(match)
	local comment = {}
	Array.forEach(match.opponents, function(opponent)
		local substitutions = (opponent.extradata or {}).substitutions
		if Logic.isEmpty(substitutions) then
			return
		end

		Array.forEach(substitutions, function(substitution)
			if Logic.isEmpty(substitution.substitute) then
				return
			end

			local subString = {}
			table.insert(subString, string.format('%s stands in',
				tostring(PlayerDisplay.InlinePlayer{player = substitution.substitute})
			))

			if Logic.isNotEmpty(substitution.player) then
				table.insert(subString, string.format('for %s',
					tostring(PlayerDisplay.InlinePlayer{player = substitution.player})
				))
			end

			if opponent.type == Opponent.team then
				local team = TeamTemplate.getRawOrNil(opponent.template)
				if team then
					table.insert(subString, string.format('on <b>%s</b>', Page.makeInternalLink(team.shortname, team.page)))
				end
			end

			if Table.isNotEmpty(substitution.games) then
				local gamesNoun = Logic.emptyOr(Info.config.match2.gameNoun, 'game') .. (#substitution.games > 1 and 's' or '')
				table.insert(subString, string.format('on %s %s', gamesNoun, mw.text.listToText(substitution.games)))
			end

			if String.isNotEmpty(substitution.reason) then
				table.insert(subString, string.format('due to %s', substitution.reason))
			end

			table.insert(comment, table.concat(subString, ' ') .. '.')
		end)
	end)

	return comment
end

---Creates display components for caster(s).
---@param casters {name: string?, displayName: string?, flag: string?}[]
---@return (string|Widget|nil)[]
function DisplayHelper.createCastersDisplay(casters)
	return Array.map(casters, function(caster)
		if not caster.name then
			return nil
		end

		local casterLink = Link{children = caster.displayName, link = caster.name}
		if not caster.flag then
			return casterLink
		end

		return HtmlWidgets.Fragment{children = {
			Flags.Icon(caster.flag),
			NONBREAKING_SPACE,
			casterLink,
		}}
	end)
end

---Displays the map name and link, and the status of the match if it had an unusual status.
---@param game MatchGroupUtilGame
---@param config {noLink: boolean?}?
---@return string
function DisplayHelper.MapAndStatus(game, config)
	local mapText = DisplayHelper.Map(game, config)

	local walkoverType = (Array.find(game.opponents or {}, function(opponent)
		return opponent.status == 'FF'
			or opponent.status == 'DQ'
			or opponent.status == 'L'
	end) or {}).status

	if not walkoverType then return mapText end

	---@param walkoverDisplay string
	---@return string
	local toDisplay = function(walkoverDisplay)
		return mapText .. NONBREAKING_SPACE .. '<i>(' .. walkoverDisplay .. ')</i>'
	end

	if walkoverType == 'L' then
		return toDisplay('w/o')
	else
		return toDisplay(walkoverType:lower())
	end
end

---Displays the map name and map-mode.
---@param game MatchGroupUtilGame
---@param config {noLink: boolean?}?
---@return string
function DisplayHelper.MapAndMode(game, config)
	local MapModes = require('Module:MapModes')

	local mapText = DisplayHelper.Map(game, config)

	if Logic.isEmpty(game.mode) then
		return mapText
	end
	return MapModes.get{mode = game.mode} .. mapText
end

---Displays the map name and link.
---@param game MatchGroupUtilGame
---@param config {noLink: boolean?}?
---@return string
function DisplayHelper.Map(game, config)
	config = config or {}
	local mapText
	if game.map and game.mapDisplayName then
		mapText = '[[' .. game.map .. '|' .. game.mapDisplayName .. ']]'
	elseif game.map and not config.noLink then
		mapText = '[[' .. game.map .. ']]'
	else
		mapText = game.map or 'Unknown'
	end
	if game.status == 'notplayed' then
		mapText = '<s>' .. mapText .. '</s>'
	end
	return mapText
end

---@param opponent table
---@param gameStatus string?
---@return string
function DisplayHelper.MapScore(opponent, gameStatus)
	if gameStatus == 'notplayed' then
		return ''
	elseif opponent.status and opponent.status ~= 'S' then
		return opponent.status
	end
	return opponent.score and tostring(opponent.score) or ''
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
---@return Widget
function DisplayHelper.DefaultFfaMatchSummaryContainer(props)
	local MatchSummaryModule = Lua.import('Module:MatchSummary/Ffa')

	assert(MatchSummaryModule.getByMatchId, 'Expected MatchSummary/Ffa.getByMatchId to be a function')

	return MatchSummaryModule.getByMatchId(props)
end

---@param props table
---@return Html
function DisplayHelper.DefaultGameSummaryContainer(props)
	local GameSummaryModule = Lua.import('Module:GameSummary')

	assert(
		type(GameSummaryModule.getGameByMatchId) == 'function',
		'Expected GameSummary.getGameByMatchId to be a function'
	)

	return GameSummaryModule.getGameByMatchId(props)
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
