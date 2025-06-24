---
-- @Liquipedia
-- page=Module:MatchTicker/DisplayComponents
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Holds DisplayComponents for the MatchTicker module

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local I18n = Lua.import('Module:I18n')
local Icon = Lua.import('Module:Icon')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Timezone = Lua.import('Module:Timezone')
local VodLink = Lua.import('Module:VodLink')

local HighlightConditions = Lua.import('Module:HighlightConditions')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
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
local UTC = Timezone.getTimezoneString{timezone = 'UTC'}

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
	return mw.html.create('div'):node(self.root)
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
	local bestof = self.match.asGame and self:gameTitle() or self:bestof()
	local scores, scores2 = self:scores()
	local upperText, lowerText
	if #self.match.opponents > 2 then
		-- brackets always have an inherited header matchlists might lack them,
		-- hence use matchIndex to generate a generic one for those cases
		local headerRaw = self.match.match2bracketdata.inheritedheader
			or ('Match ' .. self.match.match2bracketdata.matchIndex)
		upperText = DisplayHelper.expandHeader(headerRaw)[1]
		if self.match.asGame then
			upperText = upperText .. ' - ' .. self:gameTitle() .. self:mapTitle()
		end
	elseif String.isNotEmpty(scores2) then
		upperText = scores2
		lowerText = scores
	elseif bestof then
		upperText = scores or VS
		lowerText = bestof
	elseif scores then
		upperText = scores
		lowerText = VS
	end
	upperText = upperText or VS

	if not lowerText then
		return self.root:wikitext(upperText)
	end

	return self.root
		:node(mw.html.create('div')
			:addClass('versus-upper'):node(upperText)
		):node(mw.html.create('div')
			:addClass('versus-lower'):wikitext('(' .. lowerText .. ')')
		)
end

---@return string?
function Versus:bestof()
	local bestof = tonumber(self.match.bestof) or 0
	if bestof > 0 then
		return Abbreviation.make{text = 'Bo' .. bestof, title = 'Best of ' .. bestof}
	end
end

---@return string
function Versus:gameTitle()
	if not self.match.asGameIndexes then
		return ''
	end
	return 'Game #' .. (table.concat(self.match.asGameIndexes, '-'))
end

---@return string
function Versus:mapTitle()
	local mapName = Logic.nilIfEmpty(self.match.map)
	if not mapName then
		return ''
	end
	return ' on ' .. mapName
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
	local delimiter = '<span>:</span>'

	local setWinner = function(score, opponentIndex)
		if winner == opponentIndex then
			return '<b>' .. score .. '</b>'
		end
		return score
	end

	Array.forEach(self.match.opponents or {}, function(opponent, opponentIndex)
		local score = Logic.isNotEmpty(opponent.status) and opponent.status ~= SCORE_STATUS and opponent.status
			or tonumber(opponent.score) or -1

		table.insert(scores, '<span>' .. setWinner(score ~= -1 and score or 0, opponentIndex) .. '</span>' )

		local score2 = tonumber((opponent.extradata or {}).score2) or 0
		table.insert(scores2, '<span>' .. setWinner(score2, opponentIndex) .. '</span>' )
		if score2 > 0 then
			hasSecondScore = true
		end
	end)

	if hasSecondScore then
		return table.concat(scores, delimiter), table.concat(scores2, delimiter)
	end

	return table.concat(scores, delimiter)
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
		:node(self:opponent(match.opponents[1], winner == 1, true):addClass('team-left'))
		:node(self:versus())
		:node(self:opponent(match.opponents[2], winner == 2):addClass('team-right'))
end

---@param opponent table
---@param isWinner boolean
---@param flip boolean?
---@return Html
function ScoreBoard:opponent(opponent, isWinner, flip)
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
	local matchPageIcon = self:_matchPageIcon()
	local td = mw.html.create('td')
		:addClass('match-filler')
		:node(mw.html.create('div')
			:addClass(matchPageIcon and 'has-matchpage' or nil)
			:node(self:countdown(matchPageIcon))
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

---@return string?
function Details:_matchPageIcon()
	local matchPage = (self.match.match2bracketdata or {}).matchpage
	if Logic.isEmpty(matchPage) then return end

	local display = mw.html.create('div')
		:addClass('btn btn-secondary')
		:wikitext(Icon.makeIcon{iconName = 'matchpopup'})

	return Page.makeInternalLink(tostring(display), matchPage)
end

---@param matchPageIcon string?
---@return Html
function Details:countdown(matchPageIcon)
	local match = self.match

	local dateString
	if Logic.readBool(match.dateexact) then
		local timestamp = DateExt.readTimestamp(match.date) + (Timezone.getOffset{timezone = match.extradata.timezoneid} or 0)
		dateString = DateExt.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
				.. (Timezone.getTimezoneString{timezone = match.extradata.timezoneid} or UTC)
	else
		dateString = mw.getContentLanguage():formatDate('F j, Y', match.date) .. UTC
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

	if Logic.readBool(match.finished) then
		local function makeVod(vod, num)
			if Logic.isEmpty(vod) then
				return nil
			end
			return VodLink.display{
				vod = vod,
				gamenum = num,
			}
		end

		local gameVods = Array.map(Array.map(match.match2games or {}, Operator.property('vod')), makeVod)

		countdownDisplay:node(makeVod(match.vod))
		Array.forEach(gameVods, function(vod)
			countdownDisplay:node(vod)
		end)
	end

	return mw.html.create('div')
		:addClass('match-countdown-wrapper')
		:node(countdownDisplay)
		:node(matchPageIcon)
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
		:addClass('tournament-flex')
		:node(mw.html.create('div')
			:addClass('tournament-text-flex')
			:wikitext('[[' .. match.pagename .. '|' .. displayName .. ']]')
		)
		:node(mw.html.create('span')
			:node(icon)
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

	local isBrMatch = #self.match.opponents ~= 2
	if isBrMatch then
		matchDisplay:node(self:brMatchRow())
	else
		matchDisplay
			:addClass(WINNER_TO_BG_CLASS[tonumber(self.match.winner)])
			:node(self:standardMatchRow())
	end

	matchDisplay:node(self:detailsRow(isBrMatch))

	return matchDisplay
end

---@param inheritedHeader string?
---@return string?
function Match:_expandHeader(inheritedHeader)
	if not inheritedHeader then
		return
	end

	local headerArray = mw.text.split(inheritedHeader, '!')

	local index = 1
	if String.isEmpty(headerArray[1]) then
		index = 2
	end

	local headerInput = 'brkts-header-' .. headerArray[index]
	local expandedHeader = I18n.translate('brkts-header-' .. headerArray[index], {round = headerArray[index + 1]})
	local failedExpandedHeader = '⧼' .. headerInput .. '⧽'
	if Logic.isEmpty(expandedHeader) or failedExpandedHeader == expandedHeader then
		return inheritedHeader
	end

	return expandedHeader
end

---@return Html
function Match:brMatchRow()
	local displayText = self:_expandHeader(self.match.match2bracketdata.inheritedheader)
		or self.match.match2bracketdata.sectionheader or DEFAULT_BR_MATCH_TEXT

	return mw.html.create('tr')
		:addClass('versus')
		:tag('td'):wikitext(displayText):done()
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
