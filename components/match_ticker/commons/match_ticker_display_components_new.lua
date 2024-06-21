---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/DisplayComponents/New
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
local StreamLinks = require('Module:Links/Stream')

local HighlightConditions = Lua.import('Module:HighlightConditions')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local VS = 'VS'
local SCORE_STATUS = 'S'
local CURRENT_PAGE = mw.title.getCurrentTitle().text
local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'
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
	return mw.html.create('div'):node(self.root)
end

---Display class for matches shown within a match ticker
---@class MatchTickerVersus
---@operator call(table): MatchTickerVersus
---@field root Html
---@field match table
local Versus = Class.new(
	function(self, match)
		self.root = mw.html.create('div'):addClass('versus')
		self.match = match
	end
)

---@return Html
function Versus:create()
	local bestof = self:bestof()
	local scores = self:scores()
	local upperText, lowerText

	if bestof then
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
			:addClass('versus-upper')
			:node(upperText or VS)
		):node(mw.html.create('div')
			:addClass('versus-lower')
			:wikitext('(' .. lowerText .. ')')
		)
end

---@return string?
function Versus:bestof()
	local bestof = tonumber(self.match.bestof) or 0
	if bestof > 0 then
		return Abbreviation.make('(Bo' .. bestof .. ')', '(Best of ' .. bestof .. ')')
	end
end

---@return string?
---@return string?
function Versus:scores()
	if self.match.date > NOW then
		return
	end

	local scores = {}

	Array.forEach(self.match.match2opponents, function(opponent, opponentIndex)
		local score = Logic.isNotEmpty(opponent.status) and opponent.status ~= SCORE_STATUS and opponent.status
			or tonumber(opponent.score) or -1

		table.insert(scores, score)
	end)

	return table.concat(scores, ' : ')
end

---Display class for matches shown within a match ticker
---@class MatchTickerScoreBoard
---@operator call(table): MatchTickerScoreBoard
---@field root Html
---@field match table
local ScoreBoard = Class.new(
	function(self, match)
		self.root = mw.html.create('div'):addClass('match-scoreboard')
		self.match = match
	end
)

---@return Html
function ScoreBoard:create()
	local match = self.match
	local winner = tonumber(match.winner)

	return self.root
		:node(self:opponent(match.match2opponents[1], winner == 1, true):addClass('team-left'))
		:node(self:versus())
		:node(self:opponent(match.match2opponents[2], winner == 2):addClass('team-right'))
end

---@param opponentData table
---@param isWinner boolean
---@param flip boolean?
---@return Html
function ScoreBoard:opponent(opponentData, isWinner, flip)
	local opponent = Opponent.fromMatch2Record(opponentData)
	---@cast opponent -nil
	if Opponent.isEmpty(opponent) or Opponent.isTbd(opponent) and opponent.type ~= Opponent.literal then
		opponent = Opponent.tbd(Opponent.literal)
	end

	local opponentName = Opponent.toName(opponent)
	if not opponentName then
		mw.logObject(opponent, 'Invalid Opponent, Opponent.toName returns nil')
		opponentName = ''
	end

	local opponentDisplay = mw.html.create('div')
		:node(OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = flip,
			showLink = opponentName:gsub('_', ' ') ~= CURRENT_PAGE
		})

	return opponentDisplay
end

---@return Html
function ScoreBoard:versus()
	return Versus(self.match):create()
end

---Display class for matches shown within a match ticker
---@class MatchTickerDetails
---@operator call(table): MatchTickerMatch
---@field root Html
---@field hideTournament boolean
---@field onlyHighlightOnValue string?
---@field match table
local Details = Class.new(
	function(self, args)
		assert(args.match, 'No Match passed to MatchTickerDetails class')
		self.root = mw.html.create('div'):addClass('match-details')
		self.hideTournament = args.hideTournament
		self.onlyHighlightOnValue = args.onlyHighlightOnValue
		self.match = args.match
	end
)

---@return Html
function Details:create()
	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	if highlightCondition(self.match, {onlyHighlightOnValue = self.onlyHighlightOnValue}) then
		self.root:addClass(HIGHLIGHT_CLASS)
	end

	return self.root
		:node(self:streams())
		:node(self:tournament())
		:node(self:countdown())
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

	dateString = 'June 22, 2024 - 02:00' .. (Timezone.getTimezoneString('UTC'))

	local countdownArgs = {
		date = dateString,
		finished = match.finished
	}

	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:node(Countdown._create(countdownArgs))

	return countdownDisplay
end

---@return Html?
function Details:streams()
	local match = self.match
	local streams = mw.html.create('div')
		:addClass('match-streams')

	if Table.isNotEmpty(match.stream) then
		local streams = {}

		-- Copy from Module:Countdown
		-- New format stream (twitch_en_2)
		for rawHost, stream in pairs(match.stream) do
			-- Check if its a new format stream
			if #(mw.text.split(rawHost, '_', true)) == 3 then
				-- Parse the string
				local key = StreamLinks.StreamKey(rawHost)
				-- Not allowed to add new keys while iterating it, add to another table
				streams[key:toString()] = stream
			else
				streams[rawHost] = stream
			end
		end

		for platformName, targetStream in pairs(streams) do
			-- TODO
		end
	else
		links:node(mw.html.create('span')
			:wikitext('no streams')
		)
	end

	return links
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
		:node(mw.html.create('div')
			:addClass('tournament-icon')
			:node(mw.html.create('div')
				:wikitext(icon)
			)
		)
		:node(mw.html.create('div')
			:addClass('tournament-text')
			:wikitext('[[' .. match.pagename .. '|' .. displayName .. ']]')
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
		self.root = mw.html.create('div'):addClass('match')
		self.config = args.config
		self.match = args.match
	end
)

---@return Html
function Match:create()
	self.root:node(self:standardMatchRow())
	self.root:node(self:detailsRow())

	return self.root
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
	local expandedHeader = mw.message.new('brkts-header-' .. headerArray[index])
			---@diagnostic disable-next-line: param-type-mismatch
			:params(headerArray[index + 1] or ''):plain() --[[@as string]]
	local failedExpandedHeader = '⧼' .. headerInput .. '⧽'
	if Logic.isEmpty(expandedHeader) or failedExpandedHeader == expandedHeader then
		return inheritedHeader
	end

	return expandedHeader
end

---@return Html
function Match:standardMatchRow()
	return ScoreBoard(self.match):create()
end

---@return Html
function Match:detailsRow()
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
