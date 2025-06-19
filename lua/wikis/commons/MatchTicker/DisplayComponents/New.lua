---
-- @Liquipedia
-- page=Module:MatchTicker/DisplayComponents/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Holds DisplayComponents for the MatchTicker module
-- It contains the new html structure intented to be use for the new Main Page

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Timezone = Lua.import('Module:Timezone')
local StreamLinks = Lua.import('Module:Links/Stream')
local VodLink = Lua.import('Module:VodLink')

local DefaultMatchTickerDisplayComponents = Lua.import('Module:MatchTicker/DisplayComponents')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Title = Lua.import('Module:Widget/Tournament/Title')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local CURRENT_PAGE = mw.title.getCurrentTitle().text
local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'
local UTC = Timezone.getTimezoneString{timezone = 'UTC'}

---Display class for matches shown within a match ticker
---@class NewMatchTickerScoreBoard
---@operator call(table): NewMatchTickerScoreBoard
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

	if #match.opponents > 2 then
		--- When "FFA/BR" we don't want to display the opponents, as there are more than 2.
		return self.root:node(self:versus())
	end

	return self.root
		:node(self:opponent(match.opponents[1], winner == 1, true):addClass('team-left'))
		:node(self:versus())
		:node(self:opponent(match.opponents[2], winner == 2):addClass('team-right'))
end

---@param opponent standardOpponent
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

	local opponentDisplay = mw.html.create('div')
		:node(OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = flip,
			showLink = opponentName:gsub('_', ' ') ~= CURRENT_PAGE
		})

	if isWinner then
		opponentDisplay:addClass('match-winner')
	end

	return opponentDisplay
end

---@return Html
function ScoreBoard:versus()
	return mw.html.create('div')
		:addClass('versus')
		:node(DefaultMatchTickerDisplayComponents.Versus(self.match):create())
end

---Display class for the details of a match displayed at the bottom of a match ticker
---@class NewMatchTickerDetails
---@operator call(table): NewMatchTickerMatch
---@field root Html
---@field hideTournament boolean
---@field onlyHighlightOnValue string?
---@field displayGameIcons boolean
---@field match table
local Details = Class.new(
	function(self, args)
		assert(args.match, 'No Match passed to MatchTickerDetails class')
		self.root = mw.html.create('div'):addClass('match-details')
		self.hideTournament = args.hideTournament
		self.onlyHighlightOnValue = args.onlyHighlightOnValue
		self.displayGameIcons = args.displayGameIcons
		self.match = args.match
	end
)

---@return Html
function Details:create()
	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	if highlightCondition(self.match, {onlyHighlightOnValue = self.onlyHighlightOnValue}) then
		self.root:addClass(HIGHLIGHT_CLASS)
	end

	local matchBottomBar = mw.html.create('div'):addClass('match-bottom-bar')
	matchBottomBar:node(self:countdown())

	matchBottomBar:node(MatchPageButton{
		matchId = self.match.match2id,
		hasMatchPage = Logic.isNotEmpty(self.match.match2bracketdata.matchpage),
	})

	return self.root
		:node(mw.html.create('div'):addClass('match-links')
			:node(self:tournament())
			:node(self:streamsOrVods())
		)
		:node(matchBottomBar)
end

---It will display both countdown and date of the match so the user can select which one to show
---@return Html
function Details:countdown()
	local match = self.match

	local dateString
	if Logic.readBool(match.dateexact) then
		local timestamp = DateExt.readTimestamp(match.date) + (Timezone.getOffset{timezone = match.extradata.timezoneid} or 0)
		dateString = DateExt.formatTimestamp('F j, Y - H:i', timestamp) .. ' '
				.. (Timezone.getTimezoneString{timezone = match.extradata.timezoneid} or UTC)
	else
		dateString = mw.getContentLanguage():formatDate('F j, Y', match.date) .. UTC
	end

	local countdownArgs = {
		date = dateString,
		finished = match.finished,
		showCompleted = true,
	}

	local countdownDisplay = mw.html.create('span')
		:addClass('match-countdown')
		:node(Countdown._create(countdownArgs))

	return countdownDisplay
end

---@return Html?
function Details:streamsOrVods()
	local match = self.match

	if not Logic.readBool(match.finished) then
		return mw.html.create('div')
			:addClass('match-streams')
			:wikitext(table.concat(StreamLinks.buildDisplays(StreamLinks.filterStreams(match.stream)) or {}))
	end

	local vods = mw.html.create('div')
			:addClass('match-streams')

	---@param obj table
	---@param index integer?
	local addVod = function(obj, index)
		vods:node(Logic.isNotEmpty(obj.vod) and VodLink.display{
			vod = obj.vod,
			gamenum = index,
		} or nil)
	end

	addVod(match)
	Array.forEach(match.match2games or {}, addVod)

	return vods
end

---@return Widget?
function Details:tournament()
	if self.hideTournament then
		return
	end

	local match = self.match

	return HtmlWidgets.Div{
		classes = {'match-tournament'},
		children = {
			Title{
				tournament = {
					pageName = match.pagename,
					displayName = Logic.emptyOr(
						match.tickername,
						match.tournament,
						match.parent:gsub('_', ' ')
					),
					tickerName = match.tickername,
					icon = match.icon,
					iconDark = match.icondark,
					series = match.series,
					game = match.game,
				},
				displayGameIcon = self.displayGameIcons
			}
		}
	}
end

---Display class for matches shown within a match ticker
---@class NewMatchTickerMatch
---@operator call({config: MatchTickerConfig, match: table}): NewMatchTickerMatch
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

---@return Html
function Match:standardMatchRow()
	return ScoreBoard(self.match):create()
end

---@return Html
function Match:detailsRow()
	return Details{
		match = self.match,
		hideTournament = self.config.hideTournament,
		onlyHighlightOnValue = self.config.onlyHighlightOnValue,
		displayGameIcons = self.config.displayGameIcons
	}:create()
end

return {
	Match = Match,
	Details = Details,
	ScoreBoard = ScoreBoard,
}
