---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/DisplayComponents
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Holds DisplayComponents for the MatchTicker module

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local DateExt = require('Module:Date/Ext')
local String = require('Module:StringUtils')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local VodLink = require('Module:VodLink')

local HighlightConditions = Lua.import('Module:HighlightConditions', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local VS = 'vs'
local SCORE_STATUS = 'S'
local CURRENT_PAGE = mw.title.getCurrentTitle().text
local DEFAULT_BR_MATCH_TEXT = 'Unknown Round'
local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'
local WINNER_TO_BG_CLASS = {
	[0] = 'recent-matches-draw',
	'recent-matches-left',
	'recent-matches-right',
}
local TOURNAMENT_DEFAULT_ICON = 'Generic_Tournament_icon.png'
local NOW = os.date('%Y-%m-%d %H:%M', os.time(os.date('!*t') --[[@as osdateparam]]))

---Display class for the header of a match ticker
---@class MatchTickerHeader
---@operator call(string|number|nil): MatchTickerHeader
---@field root Html
local Header = Class.new(
	function(self, text)
		self.root = mw.html.create('div')
			:addClass('infobox-header')
			:wikitext(text)
	end
)

---@param class string?
---@return MatchTickerHeader
function Header:addClass(class)
	self.root:addClass(class)
	return self
end

---@return Html
function Header:create()
	return self.root
end

---Display class for matches shown within a match ticker
---@class MatchTickerVersus
---@operator call(table): MatchTickerVersus
---@field root Html
---@field match table
local Versus = Class.new(
	function(self, match)
		self.root = mw.html.create('div')
		self.match = match
	end
)

---@return Html
function Versus:create()
	local bestof = self:bestof()
	local scores, scores2 = self:scores()
	local upperText, lowerText
	if String.isNotEmpty(scores2) then
		upperText = scores2
		lowerText = scores
	elseif bestof then
		upperText = scores or VS
		lowerText = bestof
	elseif scores then
		upperText = scores
		lowerText = VS
	end

	if not lowerText then
		return self.root:wikitext(VS)
	end

	return self.root
		:node(mw.html.create('div')
			:css('line-height', '1.1'):node(upperText or VS)
		):node(mw.html.create('div')
			:addClass('versus-lower'):wikitext('(' .. lowerText .. ')')
		)
end

---@return string?
function Versus:bestof()
	local bestof = tonumber(self.match.bestof) or 0
	if bestof > 0 then
		return Abbreviation.make('Bo' .. bestof, 'Best of ' .. bestof)
	end
end

---@return string?
---@return string?
function Versus:scores()
	if self.match.date > NOW then
		return
	end

	local winner = tonumber(self.match.winner)

	local scores, scores2 = {}, {}
	local hasSecondScore

	local setWinner = function(score, opponentIndex)
		if winner == opponentIndex then
			return '<b>' .. score .. '</b>'
		end
		return score
	end

	Array.forEach(self.match.match2opponents, function(opponent, opponentIndex)
		local score = opponent.status ~= SCORE_STATUS and opponent.status
			or tonumber(opponent.score) or -1

		table.insert(scores, setWinner(score ~= -1 and score or 0, opponentIndex))

		local score2 = tonumber((opponent.extradata or {}).score2) or 0
		table.insert(scores2, setWinner(score2, opponentIndex))
		if score2 > 0 then
			hasSecondScore = true
		end
	end)

	if hasSecondScore then
		return table.concat(scores, ':'), table.concat(scores2, ':')
	end

	return table.concat(scores, ':')
end

---Display class for matches shown within a match ticker
---@class MatchTickerScoreBoard
---@operator call(table): MatchTickerScoreBoard
---@field root Html
---@field match table
local ScoreBoard = Class.new(
	function(self, match)
		self.root = mw.html.create('tr')
		self.match = match
	end
)

---@return Html
function ScoreBoard:create()
	local match = self.match
	local winner = tonumber(match.winner)

	return self.root
		:addClass(WINNER_TO_BG_CLASS[winner])
		:node(self:opponent(match.match2opponents[1], winner == 1, true):addClass('team-left'))
		:node(self:versus())
		:node(self:opponent(match.match2opponents[2], winner == 2):addClass('team-right'))
end

---@param opponent standardOpponent
---@param isWinner boolean
---@param flip boolean?
---@return Html
function ScoreBoard:opponent(opponent, isWinner, flip)
	opponent = Opponent.fromMatch2Record(opponent)
	if Opponent.isEmpty(opponent) or Opponent.isTbd(opponent) and opponent.type ~= Opponent.literal then
		opponent = Opponent.tbd(Opponent.literal)
	end

	local opponentName = Opponent.toName(opponent)
	if not opponentName then
		mw.logObject(opponent, 'Invalid Opponent, Opponent.toName returns nil')
		opponentName = ''
	end

	local opponentDispaly = mw.html.create('td')
		:node(OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = flip,
			showLink = opponentName:gsub('_', ' ') ~= CURRENT_PAGE
		})

	if isWinner then
		opponentDispaly:css('font-weight', 'bold')
	end

	return opponentDispaly
end

---@return Html
function ScoreBoard:versus()
	return mw.html.create('td')
		:addClass('versus')
		:node(Versus(self.match):create())
end

---Display class for matches shown within a match ticker
---@class MatchTickerDetails
---@operator call(table): MatchTickerMatch
---@field root Html
---@field hideTournament boolean
---@field isBrMatch boolean
---@field onlyHighlightOnValue string?
---@field match table
local Details = Class.new(
	function(self, args)
		assert(args.match, 'No Match passed to MatchTickerDetails class')
		self.root = mw.html.create('tr')
		self.hideTournament = args.hideTournament
		self.isBrMatch = args.isBrMatch
		self.onlyHighlightOnValue = args.onlyHighlightOnValue
		self.match = args.match
	end
)

---@return Html
function Details:create()
	local td = mw.html.create('td')
		:addClass('match-filler')
		:node(mw.html.create('span')
			:node(self:countdown())
			:node(self:tournament())
		)

	if not self.isBrMatch then
		td:attr('colspan', 3)
	end

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament

	if highlightCondition(self.match, {onlyHighlightOnValue = self.onlyHighlightOnValue}) then
		self.root:addClass(HIGHLIGHT_CLASS)
	end

	return self.root:node(td)
end

---@return Html
function Details:countdown()
	local match = self.match

	local dateString
	if Logic.readBool(match.dateexact) then
		local timestamp = DateExt.readTimestamp(match.date) + (Timezone.getOffset(match.extradata.timezoneid) or 0)
		dateString = DateExt.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
				.. (Timezone.getTimezoneString(match.extradata.timezoneid) or (Timezone.getTimezoneString('UTC')))
	else
		dateString = mw.getContentLanguage():formatDate('F j, Y', match.date) .. (Timezone.getTimezoneString('UTC'))
	end

	local countdownArgs = Table.merge(match.stream or {}, {
		rawcountdown = not Logic.readBool(match.finished),
		rawdatetime = Logic.readBool(match.finished),
		date = dateString,
		finished = match.finished
	})

	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:node(Countdown._create(countdownArgs))
		:node('&nbsp;&nbsp;')

	if String.isNotEmpty(match.vod) then
		countdownDisplay:node(VodLink.display{vod = match.vod})
	end

	return countdownDisplay
end

---@return Html?
function Details:tournament()
	if self.hideTournament then
		return
	end

	local match = self.match

	local icon = LeagueIcon.display{
		icon = Logic.emptyOr(match.icon, TOURNAMENT_DEFAULT_ICON),
		iconDark = match.icondark,
		link = match.pagename,
		name = match.tournament,
		options = {noTemplate = true},
	}

	local displayName = Logic.emptyOr(
		match.tickername,
		match.tournament,
		match.parent:gsub('_', ' ')
	)

	return mw.html.create('div')
		:addClass('tournament')
		:node(mw.html.create('span')
			:css('float', 'right')
			:node(icon)
		)
		:node(mw.html.create('div')
			:addClass('tournament-text')
			:wikitext('[[' .. match.pagename .. '|' .. displayName .. ']]&nbsp;&nbsp;')
		)

end

---Display class for matches shown within a match ticker
---@class MatchTickerMatch
---@operator call({config: MatchTickerConfig, match: table}): MatchTickerMatch
---@field root Html
---@field config MatchTickerConfig
---@field match table
local Match = Class.new(
	function(self, args)
		self.root = mw.html.create('table')
			:addClass('wikitable wikitable-striped infobox_matches_content')
		self.config = args.config
		self.match = args.match
	end
)

---@return Html
function Match:create()
	local matchDisplay = mw.html.create('table')
		:addClass('wikitable wikitable-striped infobox_matches_content')

	local isBrMatch = #self.match.match2opponents ~= 2
	if isBrMatch then
		matchDisplay:node(self:brMatchRow())
	else
		matchDisplay:node(self:standardMatchRow())
	end

	matchDisplay:node(self:detailsRow(isBrMatch))

	return matchDisplay
end

---@return Html
function Match:brMatchRow()
	local displayText = self.match.match2bracketdata.sectionheader or DEFAULT_BR_MATCH_TEXT

	local inheritedHeader = self.match.match2bracketdata.inheritedheader
	if inheritedHeader then
		local headerArray = mw.text.split(inheritedHeader, '!')

		local index = 1
		if String.isEmpty(headerArray[1]) then
			index = 2
		end
		displayText = Logic.emptyOr(
			mw.message.new('brkts-header-' .. headerArray[index]):params(headerArray[index + 1] or ''):plain(),
			inheritedHeader
		)--[[@as string]]
	end


	return mw.html.create('tr')
		:addClass('versus')
		:wikitext(displayText)
end

---@return Html
function Match:standardMatchRow()
	return ScoreBoard(self.match):create()
end

---@param isBrMatch boolean
---@return Html
function Match:detailsRow(isBrMatch)
	return Details{
		match = self.match,
		hideTournament = self.config.hideTournament,
		isBrMatch = isBrMatch,
		onlyHighlightOnValue = self.config.onlyHighlightOnValue
	}:create()
end

return {
	Header = Header,
	Match = Match,
	Details = Details,
	ScoreBoard = ScoreBoard,
	Versus = Versus,
}
