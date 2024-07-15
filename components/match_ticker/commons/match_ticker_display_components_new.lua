---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/DisplayComponents/New
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

-- Holds DisplayComponents for the MatchTicker module
-- It contains the new html structure intented to be use for the new Dota2 Main Page (for now)
-- Will most likely be expanded to other games in the future and other pages

local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local DateExt = require('Module:Date/Ext')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local StreamLinks = require('Module:Links/Stream')
local Page = require('Module:Page')
local DefaultMatchTickerDisplayComponents = require('Module:MatchTicker/DisplayComponents')

local HighlightConditions = Lua.import('Module:HighlightConditions')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local CURRENT_PAGE = mw.title.getCurrentTitle().text
local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'
local TOURNAMENT_DEFAULT_ICON = 'Generic_Tournament_icon.png'

local PLATFORM_TO_ICON = {
	cc163 = 'cc',
	huomao = 'huomaotv',
	huya = 'huyatv',
	himo = 'nimotv',
}

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

---It will display both countdown and date of the match so the user can select which one to show
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
	local links = mw.html.create('div')
		:addClass('match-streams')

	mw.logObject(match.stream, 'match.stream')

	if Table.isNotEmpty(match.stream) then
		local streams = {}

		-- Standardize the stream data to always use the platform as key (because of the new format ex: twitch_en_2)
		for rawHost, stream in pairs(match.stream) do
			local streamParts = mw.text.split(rawHost, '_', true)
			if #streamParts == 3 then
				local key = StreamLinks.StreamKey(rawHost)
				streams[key.platform] = stream
			else
				streams[rawHost] = stream
			end
		end

		local streamLinks = ''

		-- Iterate over the streams and create the different links
		for platformName, targetStream in pairs(streams) do
			local streamLink = mw.ext.StreamPage.resolve_stream(platformName, targetStream)

			if streamLink then
				local icon = '<i class="lp-icon lp-icon-21 lp-' .. (PLATFORM_TO_ICON[platformName] or platformName) .. '"></i>'

				-- TL.net specific
				if platformName == 'stream' then
					streamLinks = streamLinks ..
						Page.makeExternalLink(icon, 'https://tl.net/video/streams/' .. streamLink)
				else
					streamLinks = streamLinks ..
						Page.makeInternalLink({}, icon, 'Special:Stream/' .. platformName .. '/' .. streamLink)
				end
			end
		end

		links:wikitext(streamLinks)
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
		:addClass('match-tournament')
		:node(mw.html.create('div')
			:addClass('tournament-icon')
			:node(mw.html.create('div')
				:wikitext(icon)
			)
		)
		:node(mw.html.create('div')
			:addClass('tournament-text')
			:wikitext(Page.makeInternalLink({}, displayName, match.pagename))
		)

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
		onlyHighlightOnValue = self.config.onlyHighlightOnValue
	}:create()
end

return {
	Match = Match,
	Details = Details,
	ScoreBoard = ScoreBoard,
}
