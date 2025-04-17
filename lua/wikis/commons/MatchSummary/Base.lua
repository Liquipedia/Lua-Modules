---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Links = Lua.import('Module:Links')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local MATCH_LINK_PRIORITY = Lua.import('Module:Links/MatchPriorityGroups', {loadData = true})
local TBD = Abbreviation.make('TBD', 'To Be Determined')

---@class MatchSummaryHeader
---@operator call: MatchSummaryHeader
---@field root Html
---@field leftElement string|Html|number|nil
---@field leftScoreElement Html?
---@field rightElement string|Html|number|nil
---@field rightScoreElement Html?
local Header = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-header-dev')
			:css('justify-content', 'center')
	end
)

---@param content string|Html|number|nil
---@return MatchSummaryHeader
function Header:leftOpponent(content)
	self.leftElement = content
	return self
end

---@param content Html
---@return MatchSummaryHeader
function Header:leftScore(content)
	self.leftScoreElement = content:addClass('brkts-popup-header-opponent-score-left')
	return self
end

---@param content Html
---@return MatchSummaryHeader
function Header:rightScore(content)
	self.rightScoreElement = content:addClass('brkts-popup-header-opponent-score-right')
	return self
end

---@param content string|Html|number|nil
---@return MatchSummaryHeader
function Header:rightOpponent(content)
	self.rightElement = content
	return self
end

---@param opponent standardOpponent
---@param side 'left'|'right'
---@param style teamStyle?
---@return Html
function Header:createOpponent(opponent, side, style)
	local showLink = not Opponent.isTbd(opponent) and true or false
	return OpponentDisplay.BlockOpponent{
		flip = side == 'left',
		opponent = opponent,
		showLink = showLink,
		overflow = 'ellipsis',
		teamStyle = style or 'short',
	}
end

---@param opponent standardOpponent
---@return Html
function Header:createScore(opponent)
	local isWinner, scoreText
	if opponent.placement2 then
		-- Bracket Reset, show W/L
		if opponent.placement2 == 1 then
			isWinner = true
			scoreText = 'W'
		else
			isWinner = false
			scoreText = 'L'
		end
	else
		isWinner = opponent.placement == 1 or opponent.advances
		scoreText = OpponentDisplay.InlineScore(opponent)
	end

	return OpponentDisplay.BlockScore{
		isWinner = isWinner,
		scoreText = scoreText,
	}
end

---@return Html
function Header:create()
	return self.root
		:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-left')
			:node(self.leftElement)
			:node(self.leftScoreElement or '')
			:done()
		:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-right')
			:node(self.rightScoreElement or '')
			:node(self.rightElement)
			:done()
end

---@class MatchSummaryFooter
---@operator call: MatchSummaryFooter
---@field root Html
---@field inner Html
---@field elements (Html|string|number)[]
local Footer = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-footer')
		self.inner = mw.html.create('div')
			:addClass('brkts-popup-spaced vodlink')
		self.elements = {}
	end
)

---@param element Html|string|number|nil
---@return MatchSummaryFooter
function Footer:addElement(element)
	table.insert(self.elements, element)
	return self
end

---@param link string
---@param icon string
---@param iconDark string?
---@param text string
---@return MatchSummaryFooter
function Footer:addLink(link, icon, iconDark, text)
	local content
	if String.isEmpty(iconDark) then
		content = '[[' .. icon .. '|link=' .. link .. '|32px|' .. text .. '|alt=' .. link .. ']]'
	else
		---@cast iconDark -nil
		content = '[[' .. icon .. '|link=' .. link .. '|32px|' .. text .. '|alt=' .. link .. '|class=show-when-light-mode]]'
			.. '[[' .. iconDark .. '|link=' .. link .. '|32px|' .. text .. '|alt=' .. link .. '|class=show-when-dark-mode]]'
	end

	table.insert(self.elements, content)
	return self
end

---@param links table<string, string|table>
---@return MatchSummaryFooter
function Footer:addLinks(links)
	local processLink = function(linkType, link)
		local currentLinkData = Links.getMatchIconData(linkType)
		if not currentLinkData then
			mw.log('Unknown link: ' .. linkType)
		elseif type(link) == 'table' then
			for gameIdx, gameLink in Table.iter.spairs(link) do
				local newText = currentLinkData.text .. ' on Game ' .. gameIdx
				self:addLink(gameLink, currentLinkData.icon, currentLinkData.iconDark, newText)
			end
		else
			self:addLink(link, currentLinkData.icon, currentLinkData.iconDark, currentLinkData.text)
		end
	end

	local processedLinks = {}
	Array.forEach(MATCH_LINK_PRIORITY, function(linkType)
		for linkKey, link in Table.iter.pairsByPrefix(links, linkType, {requireIndex = false}) do
			processLink(linkKey, link)
			processedLinks[linkKey] = true
		end
	end)

	for linkKey, link in Table.iter.spairs(links) do
	    -- Handle links not already processed via priority list
		if not processedLinks[linkKey] then
			processLink(linkKey, link)
		end
	end

	return self
end

---@return Html?
function Footer:create()
	if Table.isEmpty(self.elements) then
		return
	end
	for _, element in ipairs(self.elements) do
		self.inner:node(element)
	end
	self.root:node(self.inner)
	return self.root
end

---@class MatchSummaryMatch
---@operator call: MatchSummaryMatch
---@field root Html
---@field headerElement Html?
---@field bodyElement Widget|Html?
---@field commentElement Widget?
---@field footerElement Html?
local Match = Class.new(
	function(self)
		self.root = mw.html.create()
	end
)

---@param header MatchSummaryHeader
---@return MatchSummaryMatch
function Match:header(header)
	self.headerElement = header:create()
	return self
end

---@param body Widget
---@return MatchSummaryMatch
function Match:body(body)
	self.bodyElement = body
	return self
end

---@param comment Widget
---@return MatchSummaryMatch
function Match:comment(comment)
	self.commentElement = comment
	return self
end

---@param footer MatchSummaryFooter
---@return MatchSummaryMatch
function Match:footer(footer)
	self.footerElement = footer:create()
	return self
end

---@return Html
function Match:create()
	self.root
		:node(self.headerElement)
		:node(MatchSummaryWidgets.Break{})
		:node(self.bodyElement)
		:node(MatchSummaryWidgets.Break{})
		:node(self.commentElement)
		:node(MatchSummaryWidgets.Break{})
		:node(self.footerElement)

	return self.root
end

---@class MatchSummary
---@operator call(string?):MatchSummary
---@field Header MatchSummaryHeader
---@field Footer MatchSummaryFooter
---@field Match MatchSummaryMatch
---@field matches Html[]?
---@field headerElement Html?
---@field root Html?
local MatchSummary = Class.new()
MatchSummary.Header = Header
MatchSummary.Footer = Footer
MatchSummary.Match = Match

---@param width string?
---@return MatchSummary
function MatchSummary:init(width)
	self.matches = {}
	self.root = mw.html.create('div')
		:addClass('brkts-popup')
		:css('width', width)
	return self
end

---@param cssClass string?
---@return MatchSummary
function MatchSummary:addClass(cssClass)
	self.root:addClass(cssClass)
	return self
end

---@param header MatchSummaryHeader
---@return MatchSummary
function MatchSummary:header(header)
	self.headerElement = header:create()
	return self
end

---@param match MatchSummaryMatch?
---@return MatchSummary
function MatchSummary:addMatch(match)
	if not match then return self end

	table.insert(self.matches, match:create())

	return self
end

---@return Html
function MatchSummary:create()
	self.root:node(self.headerElement)

	for _, match in ipairs(self.matches) do
		self.root:node(match)
	end

	return self.root
end

---Default header function
---@param match table
---@param options {teamStyle: teamStyle?, noScore:boolean?}?
---@return MatchSummaryHeader
function MatchSummary.createDefaultHeader(match, options)
	options = options or {}
	local teamStyle = options.teamStyle
	local header = MatchSummary.Header()

	if options.noScore then
		return header
			:leftOpponent(header:createOpponent(match.opponents[1], 'left', teamStyle))
			:rightOpponent(header:createOpponent(match.opponents[2], 'right', teamStyle))
	end

	return header
		:leftOpponent(header:createOpponent(match.opponents[1], 'left', teamStyle))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right', teamStyle))
end

-- Default body function
---@param match table
---@param createGame fun(date: string, game: table, gameIndex: integer): Widget
---@return Widget
function MatchSummary.createDefaultBody(match, createGame)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, FnUtil.curry(createGame, match.date)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.Casters{casters = match.extradata.casters},
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game}))
	)}
end

---Default footer function
---@param match table
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function MatchSummary.createDefaultFooter(match, footer)
	return MatchSummary.addVodsToFooter(match, footer):addLinks(match.links)
end

---Creates a match footer with vods if vods are set
---@param match table
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function MatchSummary.addVodsToFooter(match, footer)
	if match.vod then
		footer:addElement(VodLink.display{
			vod = match.vod,
		})
	end

	for gameIndex, game in ipairs(match.games) do
		if game.vod then
			footer:addElement(VodLink.display{
				gamenum = gameIndex,
				vod = game.vod,
			})
		end
	end

	return footer
end

---Default createMatch function for usage in Custom MatchSummary
---@param matchData table?
---@param CustomMatchSummary table
---@param options {teamStyle: teamStyle?, noScore: boolean?}?
---@return MatchSummaryMatch?
function MatchSummary.createMatch(matchData, CustomMatchSummary, options)
	if not matchData then
		return
	end

	local match = Match()

	local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
	match:header(createHeader(matchData, options))

	local createBody = CustomMatchSummary.createBody or MatchSummary.createDefaultBody
	match:body(createBody(matchData, CustomMatchSummary.createGame))

	local substituteComment = DisplayHelper.createSubstitutesComment(matchData)

	match:comment(MatchSummaryWidgets.MatchComment{
		children = WidgetUtil.collect(
			matchData.comment,
			Array.interleave(substituteComment, MatchSummaryWidgets.Break{})
		)
	})

	local createFooter = CustomMatchSummary.addToFooter or MatchSummary.createDefaultFooter
	match:footer(createFooter(matchData, MatchSummary.Footer()))

	return match
end

---Default getByMatchId function for usage in Custom MatchSummary
---@param CustomMatchSummary table
---@param args table
---@param options {teamStyle: teamStyle?, width: fun(MatchGroupUtilMatch):string?|string?, noScore:boolean?}?
---@return Html
function MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, options)
	assert(
		(type(CustomMatchSummary.createBody) == 'function' or type(CustomMatchSummary.createGame) == 'function'),
		'createBody(match) or createGame(date, game, gameIndex) must be implemented in Module:MatchSummary'
	)

	options = options or {}

	local match, bracketResetMatch = MatchGroupUtil.fetchMatchForBracketDisplay(
		args.bracketId, args.matchId)

	local width = options.width
	if type(width) == 'function' then
		width = width(match)
	end

	local matchSummary = MatchSummary():init(width)

	--additional header for when martin adds the the css and buttons for switching between match and reset match
	--if bracketResetMatch then
		--local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
		--matchSummary:header(createHeader(match, {noScore = true, teamStyle = options.teamStyle}))
		--here martin can add the buttons for switching between match and reset match
	--end

	local createMatch = CustomMatchSummary.createMatch or function(matchData)
		return MatchSummary.createMatch(matchData, CustomMatchSummary, options)
	end
	matchSummary:addMatch(createMatch(match))
	matchSummary:addMatch(createMatch(bracketResetMatch))

	return matchSummary:create()
end

---@param mapVetoes table
---@param options {game: string?, emptyMapDisplay: string?}?
---@return {firstVeto: integer?, vetoFormat: string?, vetoRounds: table[]}?
function MatchSummary.preProcessMapVeto(mapVetoes, options)
	if Logic.isEmpty(mapVetoes) then
		return
	end

	options = options or {}
	local mapInputToDisplay = function(map)
		if Logic.isEmpty(map) then
			return {name = options.emptyMapDisplay or TBD}
		end
		if options.game then
			return {name = map, link = map .. '/' .. options.game}
		end
		return {name = map, link = map}
	end

	return {
		firstVeto = tonumber(mapVetoes[1].vetostart),
		vetoFormat = mapVetoes[1].format,
		vetoRounds = Array.map(mapVetoes, function(vetoRound)
			return {
				type = vetoRound.type,
				map1 = mapInputToDisplay(vetoRound.team1 or vetoRound.decider),
				map2 = mapInputToDisplay(vetoRound.team2),
			}
		end)
	}
end

---@param games table[]
---@param maxNumberOfBans integer
---@return {[1]: string[], [2]: string[], start: integer?}[]
function MatchSummary.buildCharacterBanData(games, maxNumberOfBans)
	return Array.map(games, function(game)
		local extradata = game.extradata or {}
		return {
			MatchSummary.buildCharacterList(extradata, 'team1ban', maxNumberOfBans),
			MatchSummary.buildCharacterList(extradata, 'team2ban', maxNumberOfBans),
			start = extradata.banstart,
		}
	end)
end

---@param data table
---@param prefix string
---@param maxNumberOfCharacters integer
---@return string[]
function MatchSummary.buildCharacterList(data, prefix, maxNumberOfCharacters)
	return Array.map(Array.range(1, maxNumberOfCharacters), function(index)
		return data[prefix .. index]
	end)
end

return MatchSummary
