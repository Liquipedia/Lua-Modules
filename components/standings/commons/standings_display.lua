---
-- @Liquipedia
-- wiki=commons
-- page=Module:Standings/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local DisplayUtil = Lua.import('Module:DisplayUtil')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local SWISS_TYPE = 'swiss'
local EN_DASH = '–'

---@class standingsColumnOptions
---@field showRank boolean
---@field rankHeader string?
---@field opponentHeader string?
---@field showMatchScore boolean
---@field matchHeader string?
---@field showMatchWinRate boolean
---@field showGameScore boolean
---@field gamehHeader string?
---@field showGameDiff boolean
---@field gameDiffHeader string?
---@field showPoints boolean
---@field showHeaderRow boolean

---@class standingDisplay
---@field group standardStanding
local StandingsDisplay = Class.new(function(self, group)
	self.group = group
end)

---@param linksData table
---@return Html
function StandingsDisplay:build(linksData)
	local groupTable = self.group
	if groupTable.type == SWISS_TYPE then
		local SwissDisplay = Lua.import('Module:Standings/Display/Swiss')
		return SwissDisplay(groupTable):build()
	end

	-- set vars so that matchlists below are auto attached and collapsed
	Variables.varDefine('matchListIsCollapsed', '1')
	Variables.varDefine('matchListIsAttached', '1')

	local showRounds = #groupTable.rounds > 1 and groupTable.structure.type ~= 'gsl'
	local config = groupTable.config.display
	local tableNode = mw.html.create('div'):addClass('group-table')
		:addClass('toggle-area toggle-area-' .. #groupTable.rounds)
		:attr('data-toggle-area', #groupTable.rounds)
		:css('width', config.width)
		:node(self:_header(linksData, showRounds))
		:node(self:_countdownRow())
		:node(self:headerRow())

	Array.forEach(Array.range(1, #groupTable.rounds), function(roundIndex)
		tableNode:node(self:_buildRoundResults(roundIndex))
	end)

	return tableNode
end

---@param linksData table
---@param showRounds boolean
---@return Html
function StandingsDisplay:_header(linksData, showRounds)
	local config = self.group.config.display

	local titleNode = mw.html.create('div'):addClass('group-table-title')
		:node(config.title or 'Group')
	DisplayUtil.applyOverflowStyles(titleNode, 'wrap')

	local leftNode = showRounds and self:_dropdown() or nil

	local rightNode = mw.html.create('div'):addClass('group-table-header-right')
		:css('min-width', showRounds and config.roundWidth .. 'px' or nil)
		:node(self:_externalLinks(linksData))

	return mw.html.create('div'):addClass('group-table-header')
		:node(leftNode)
		:node(titleNode)
		:node(rightNode)
end

---@return Html
function StandingsDisplay:_dropdown()
	local groupTable = self.group
	local config = groupTable.config.display
	local status = groupTable.status

	local buttonText = status.groupFinished
		and (config.roundTitle .. ' ' .. status.currentRoundIndex)
		or 'Current'
	local buttonNode = mw.html.create('div')
		:addClass('dropdown-box-button btn btn-secondary')
		:css('width', config.roundWidth .. 'px')
		:css('min-height', '0')
		:css('border-radius', '0')
		:css('display', 'inherit')
		:wikitext(buttonText)
		:node('<span class="caret"></span>')

	local boxNode = mw.html.create('div'):addClass('dropdown-box')
	for roundIx = 1, status.currentRoundIndex do
		boxNode:tag('div'):addClass('toggle-area-button btn btn-secondary')
			:attr('data-toggle-area-btn', roundIx)
			:css('width', config.roundWidth .. 'px')
			:css('min-height', '0')
			:css('border-radius', '0')
			:css('display', 'inherit')
			:wikitext(config.roundTitle .. ' ' .. roundIx)
	end

	return mw.html.create('div'):addClass('dropdown-box-wrapper')
		:node(buttonNode)
		:node(boxNode)
end

---@param linksData table
---@return Html?
function StandingsDisplay:_externalLinks(linksData)
	local links = self.group.links
	if Logic.isEmpty(links) then return end
	---@cast links -nil

	local list = mw.html.create('span')
	for linkType, linkData in pairs(linksData) do
		local link = links[linkType]
		if link then
			list:wikitext(self:_externalLinkIcon(link, linkData.icon, linkData.iconDark, linkData.text))
		end
	end

	return list
end

---possibly use Module:image instead???
---@param link string
---@param icon string
---@param iconDark string?
---@param text string
---@return string
function StandingsDisplay:_externalLinkIcon(link, icon, iconDark, text)
	if Logic.isEmpty(iconDark) then
		return '[[' .. icon .. '|link=' .. link .. '|32px|' .. text .. '|alt=' .. link .. ']]'
	end
	---@cast iconDark -nil
	return '[[' .. icon .. '|link=' .. link .. '|32px|' .. text .. '|alt=' .. link .. '|class=show-when-light-mode]]'
		.. '[[' .. iconDark .. '|link=' .. link .. '|32px|' .. text .. '|alt=' .. link .. '|class=show-when-dark-mode]]'
end

---@return Html?
function StandingsDisplay:_countdownRow()
	local groupTable = self.group
	local config = groupTable.config.display
	local date = config.date
	local streams = config.streams
	if not date then
		date, streams = self:_getHeaderDate()
	end

	if not date then
		return
	end

	return mw.html.create('div'):addClass('group-table-countdown')
		:node(Countdown._create(Table.merge({date = date}, streams)))
end

---@return string? #date
---@return table? #streams
function StandingsDisplay:_getHeaderDate()
	local conditions = Array.map(self.group.matches, function(matchId)
		return '[[match2id::' .. matchId .. ']]'
	end)
	local match = mw.ext.LiquipediaB.lpdb('match2', {
		conditions = table.concat(conditions, ' OR '),
		query = "date, stream, dateexact",
		order = 'date asc',
		limit = 1,
	})[1]

	if not match or not Logic.readBool(match.dateexact) then
		return
	end

	return match.date, match.stream
end

---@return Html?
function StandingsDisplay:headerRow()
	local config = self.group.config.display.columns

	if not config.showHeaderRow then return end

	local th = StandingsDisplay.TextCell
	local abbr = Abbreviation.make

	return mw.html.create('div'):addClass('group-table-header-row')
		:node(config.showRank and th(config.rankHeader or abbr('#', 'Rank')) or nil)
		:node(th(config.opponentHeader or 'Participant'))
		:node(config.showMatchScore and th(config.matchHeader or 'Matches') or nil)
		:node(config.showMatchWinRate and th(abbr('Match %', 'Match win rate')) or nil)
		:node(config.showGameScore and th(config.gamehHeader or 'Games') or nil)
		:node(config.showGameDiff and th(config.gameDiffHeader or abbr('GD', 'Game difference')) or nil)
		:node(config.showPoints and th(abbr('Pts', 'Points')) or nil)
end

---@param text string
---@param class string?
---@return Html
function StandingsDisplay.TextCell(text, class)
	local contentNode = mw.html.create('div'):addClass('group-table-cell-content')
		:node(text)
	return mw.html.create('div')
		:addClass('group-table-cell')
		:addClass(class)
		:node(contentNode)
end

---@param roundIndex integer
---@return Html
function StandingsDisplay:_buildRoundResults(roundIndex)
	local templateColumns = self:_getTemplateColumns()
	local gridNode = mw.html.create('div'):addClass('group-table-results')
		:attr('data-toggle-area-content', roundIndex)
		:css('grid-template-columns', table.concat(templateColumns, ' '))

	local results = self.group.resultsByRound[roundIndex]

	local sortedOppIxs = Array.sortBy(Array.range(1, #results), function(oppIx)
		return results[oppIx].slotIndex
	end)

	Array.forEach(sortedOppIxs, function(oppIx, slotIx)
		gridNode:node(self:resultRow{
			entry = self.group.entries[oppIx],
			result = results[oppIx],
			slot = self.group.slots[slotIx]
		})
	end)

	return gridNode
end

---@return string[]
function StandingsDisplay:_getTemplateColumns()
	local config = self.group.config.display.columns
	return Array.extend(
		config.showRank and '[rank] minmax(min-content, auto)' or nil,
		'[entry] minmax(min-content, 1fr)',
		config.showMatchScore and '[match-score] minmax(min-content, auto)' or nil,
		config.showMatchWinRate and '[match-win-rate] minmax(min-content, auto)' or nil,
		config.showGameScore and '[game-score] minmax(min-content, auto)' or nil,
		config.showGameDiff and '[game-diff] minmax(min-content, auto)' or nil,
		config.showPoints and '[points] minmax(min-content, auto)' or nil
	)
end

---@param props {entry: standardStandingEntry, result: standingResult, slot: {pbg: string}}
---@return Html
function StandingsDisplay:resultRow(props)
	local result = props.result
	local config = self.group.config.display.columns

	local bgClass = result.dq and 'bg-dq'
		or result.bg and 'bg-' .. result.bg

	return mw.html.create('div'):addClass('group-table-result-row')
		:addClass(bgClass)
		:node(config.showRank and StandingsDisplay._rank(props) or nil)
		:node(self:_entry(props))
		:node(config.showMatchScore and self:_matchScore(result) or nil)
		:node(config.showMatchWinRate and StandingsDisplay._matchWinRate(result) or nil)
		:node(config.showGameScore and StandingsDisplay._gameScore(result) or nil)
		:node(config.showGameDiff and StandingsDisplay._gameDiff(result) or nil)
		:node(config.showPoints and StandingsDisplay._points(result) or nil)
end

---@param props {entry: standardStandingEntry, result: standingResult, slot: {pbg: string}}
---@return Html
function StandingsDisplay:_entry(props)
	local entry = props.entry
	local result = props.result

	local opponentNode = OpponentDisplay.InlineOpponent{
		date = self.group.options.resolveDate,
		dq = result.dq,
		note = entry.note,
		opponent = entry.opponent,
		showLink = not Opponent.isTbd(entry.opponent),
	}
	local leftNode = mw.html.create('span'):css('group-table-entry-left')
		:node(opponentNode)
	DisplayUtil.applyOverflowStyles(leftNode, 'wrap')

	local config = self.group.config.display.columns
	local rankChangeNode = StandingsDisplay._rankChange(result.rankChange)

	local entryNode = mw.html.create('div')
		:addClass('group-table-cell group-table-entry')
		:node(leftNode)
		:node(rankChangeNode)
	return StandingsDisplay._highlight(entryNode, entry.opponent)
end

function StandingsDisplay._highlight(node, opponent)
	local canHighlight = StandingsDisplay._isHighlightable(opponent)
	return node
		:addClass(canHighlight and 'brkts-opponent-hover' or nil)
		:attr('aria-label', canHighlight and Opponent.toName(opponent) or nil)
end

function StandingsDisplay._isHighlightable(opponent)
	if opponent.type == 'literal' then
		return opponent.name and opponent.name ~= '' and opponent.name ~= 'TBD' or false
	else
		return not Opponent.isTbd(opponent)
	end
end

---@param change integer
---@return Html?
function StandingsDisplay._rankChange(change)
	if not change or change == 0 then return end
	local rankChangeNode = mw.html.create('span'):addClass('group-table-rank-change')
	if change < 0 then
		return rankChangeNode
			:addClass('group-table-rank-change-up')
			:wikitext('&#x25B2;' .. -change) -- ▲
	end
	return rankChangeNode
		:addClass('group-table-rank-change-down')
		:wikitext('&#x25BC;' .. change) -- ▼
end

---@param props {entry: standardStandingEntry, result: standingResult, slot: {pbg: string}}
---@return Html
function StandingsDisplay._rank(props)
	local result = props.result

	local text = result.dq and'DQ'
		or StandingsDisplay.sumScores(result.matchScore) > 0 and result.rank .. '.'
		or ''

	local bgClass = result.dq and 'bg-dq'
		or props.slot.pbg and 'bg-' .. props.slot.pbg
	return StandingsDisplay.TextCell(text, 'group-table-rank ' .. bgClass)
end

---@param result standingResult
---@return Html
function StandingsDisplay:_matchScore(result)
	local hasDraws = self.group.options.hasDraw
	local textParts = Array.append({},
		result.matchScore.w,
		hasDraws and result.matchScore.d or nil,
		result.matchScore.l
	)
	local text = table.concat(textParts, EN_DASH)
	return StandingsDisplay.TextCell(text, 'group-table-match-score')
end

---@param scores scoreInfo
---@return unknown
function StandingsDisplay.sumScores(scores)
	return scores.w + scores.d + scores.l
end

---@param result standingResult
---@return Html
function StandingsDisplay._matchWinRate(result)
	local matchCount = StandingsDisplay.sumScores(result.matchScore)
	local text
	if matchCount > 0 then
		local winRate = result.matchScore.w / matchCount
		text = string.format('%.3f', math.floor(winRate * 1e3 + 0.5) / 1e3)
	else
		text = EN_DASH
	end

	return StandingsDisplay.TextCell(text, 'group-table-win-rate')
end

---@param result standingResult
---@return Html
function StandingsDisplay._gameScore(result)
	local text = result.gameScore.w .. EN_DASH .. result.gameScore.l
	return StandingsDisplay.TextCell(text, 'group-table-game-score')
end

---@param result standingResult
---@return Html
function StandingsDisplay._gameDiff(result)
	local gameDiff = result.gameScore.w - result.gameScore.l
	local text = gameDiff > 0
		and '+' .. gameDiff
		or tostring(gameDiff)
	return StandingsDisplay.TextCell(text, 'group-table-game-diff')
end

---@param result standingResult
---@return Html
function StandingsDisplay._points(result)
	local text = result.points .. 'p'
	return StandingsDisplay.TextCell(text, 'group-table-points')
end

return StandingsDisplay
