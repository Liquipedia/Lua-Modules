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
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayerDisplay = require('Module:Player/Display')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local Links =  Lua.import('Module:Links')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ARROW_LEFT = '[[File:Arrow sans left.svg|15x15px|link=|Left team starts]]'
local ARROW_RIGHT = '[[File:Arrow sans right.svg|15x15px|link=|Right team starts]]'
local DEFAULT_VETO_TYPE_TO_TEXT = {
	ban = 'BAN',
	pick = 'PICK',
	decider = 'DECIDER',
	defaultban = 'DEFAULT BAN',
}
local TBD = Abbreviation.make('TBD', 'To Be Determined')
local VETO_DECIDER = 'decider'

---just a base class to avoid anno warnings
---@class MatchSummaryRowInterface
---@field create fun(self): Html

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

---@class MatchSummaryRow: MatchSummaryRowInterface
---@operator call: MatchSummaryRow
---@field root Html
---@field elements Html[]
local Row = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-body-element')
		self.elements = {}
	end
)

---@param class string?
---@return MatchSummaryRow
function Row:addClass(class)
	self.root:addClass(class)
	return self
end

---@param name string
---@param value string|number|nil
---@return MatchSummaryRow
function Row:css(name, value)
	self.root:css(name, value)
	return self
end

---@param element Html|string|nil|Widget
---@return MatchSummaryRow
function Row:addElement(element)
	table.insert(self.elements, element)
	return self
end

---@param elements (Html|string)[]
---@return MatchSummaryRow
function Row:addElements(elements)
	for _, element in ipairs(elements) do
		self:addElement(element)
	end
	return self
end

---@return Html
function Row:create()
	for _, element in pairs(self.elements) do
		self.root:node(element)
	end

	return self.root
end

---@class MatchSummaryBody
---@operator call: MatchSummaryBody
---@field root Html
local Body = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-body')
	end
)

---@param cssClass string?
---@return MatchSummaryBody
function Body:addClass(cssClass)
	self.root:addClass(cssClass)
	return self
end

---@param row MatchSummaryRowInterface?
---@return MatchSummaryBody
function Body:addRow(row)
	if not row then return self end
	self.root:node(row:create())
	return self
end

---@return Html
function Body:create()
	return self.root
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
	for linkType, link in pairs(links) do
		local currentLinkData = Links.getMatchIconData(linkType)
		if not currentLinkData then
			mw.log('Unknown link: ' .. linkType)
		elseif type(link) == 'table' then
			Array.forEach(link, function(gameLink, gameIdx)
				local newText = currentLinkData.text .. ' on Game ' .. gameIdx
				self:addLink(gameLink, currentLinkData.icon, currentLinkData.iconDark, newText)
			end)
		else
			self:addLink(link, currentLinkData.icon, currentLinkData.iconDark, currentLinkData.text)
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

---@param body MatchSummaryBody|Widget
---@return MatchSummaryMatch
function Match:body(body)
	if type(body.create) == 'function' then
		---@cast body MatchSummaryBody
		self.bodyElement = body:create()
	else
		---@cast body Widget
		self.bodyElement = body
	end
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

-- Map Veto Class
---@class VetoDisplay: MatchSummaryRowInterface
---@operator call: self
---@field root Html
---@field table Html
---@field vetoTypeToText table
---@field game string?
---@field emptyMapDisplay string
local MapVeto = Class.new(
	function(self, options)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-mapveto')

		self.table = self.root:tag('table')
			:addClass('wikitable-striped')
			:addClass('collapsible')
			:addClass('collapsed')

		self.vetoTypeToText = options.vetoTypeToText or DEFAULT_VETO_TYPE_TO_TEXT
		self.game = options.game
		self.emptyMapDisplay = options.emptyMapDisplay or TBD

		self:createHeader()
	end
)

---@return self
function MapVeto:createHeader()
	self.table:tag('tr')
		:tag('th'):css('width','33%'):done()
		:tag('th'):css('width','34%'):wikitext('Map Veto'):done()
		:tag('th'):css('width','33%'):done()
	return self
end

---@param firstVeto number?
---@param format string?
---@return self
function MapVeto:vetoStart(firstVeto, format)
	format = format and ('Veto format: ' .. format)
	local textLeft
	local textCenter
	local textRight
	if firstVeto == 1 then
		textLeft = '<b>Start Map Veto</b>'
		textCenter = ARROW_LEFT
		textRight = format
	elseif firstVeto == 2 then
		textLeft = format
		textCenter = ARROW_RIGHT
		textRight = '<b>Start Map Veto</b>'
	else
		return self
	end

	self.table:tag('tr'):addClass('brkts-popup-mapveto-vetostart')
		:tag('th'):wikitext(textLeft):done()
		:tag('th'):wikitext(textCenter):done()
		:tag('th'):wikitext(textRight):done()

	return self
end

---@param map string?
---@return self
function MapVeto:addDecider(map)
	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', self.vetoTypeToText.decider)
	self:addColumnVetoMap(row, self:displayMap(map))
	self:addColumnVetoType(row, 'brkts-popup-mapveto-decider', self.vetoTypeToText.decider)

	self.table:node(row)
	return self
end

---@param vetoType string?
---@param map1 string?
---@param map2 string?
---@return self
function MapVeto:addRound(vetoType, map1, map2)
	map1, map2 = self:displayMaps(map1, map2)

	local vetoText = self.vetoTypeToText[vetoType]

	if not vetoText then return self end

	local class = 'brkts-popup-mapveto-' .. vetoType

	local row = mw.html.create('tr'):addClass('brkts-popup-mapveto-vetoround')

	self:addColumnVetoMap(row, map1)
	self:addColumnVetoType(row, class, vetoText)
	self:addColumnVetoMap(row, map2)

	self.table:node(row)
	return self
end

---@param map1 string?
---@param map2 string?
---@return string
---@return string
function MapVeto:displayMaps(map1, map2)
	if Logic.isEmpty(map1) and Logic.isEmpty(map2) then
		return TBD, TBD
	end

	return self:displayMap(map1), self:displayMap(map2)
end

---@param map string?
---@return string
function MapVeto:displayMap(map)
	if not map then
		return self.emptyMapDisplay
	end
	if not self.game then
		return Page.makeInternalLink(map) or self.emptyMapDisplay
	end
	return Page.makeInternalLink(map, map .. '/' .. self.game) or self.emptyMapDisplay
end

---@param row Html
---@param styleClass string
---@param vetoText string
---@return self
function MapVeto:addColumnVetoType(row, styleClass, vetoText)
	row:tag('td')
		:tag('span')
			:addClass(styleClass)
			:addClass('brkts-popup-mapveto-vetotype')
			:wikitext(vetoText)
	return self
end

---@param row Html
---@param map string
---@return self
function MapVeto:addColumnVetoMap(row, map)
	row:tag('td'):wikitext(map)
	return self
end

---@return Html
function MapVeto:create()
	return self.root
end

---@class MatchSummary
---@operator call(string?):MatchSummary
---@field Header MatchSummaryHeader
---@field Body MatchSummaryBody
---@field Row MatchSummaryRow
---@field Footer MatchSummaryFooter
---@field Match MatchSummaryMatch
---@field MapVeto VetoDisplay
---@field DEFAULT_VETO_TYPE_TO_TEXT table
---@field matches Html[]?
---@field headerElement Html?
---@field root Html?
local MatchSummary = Class.new()
MatchSummary.Header = Header
MatchSummary.Body = Body
MatchSummary.Row = Row
MatchSummary.Footer = Footer
MatchSummary.Match = Match
MatchSummary.MapVeto = MapVeto
MatchSummary.DEFAULT_VETO_TYPE_TO_TEXT = DEFAULT_VETO_TYPE_TO_TEXT

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

---Creates a match footer with vods if vods are set
---@param match table
---@return string?
function MatchSummary.createSubstitutesComment(match)
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
				local team = require('Module:Team').queryRaw(opponent.template)
				if team then
					table.insert(subString, string.format('on <b>%s</b>', Page.makeInternalLink(team.shortname, team.page)))
				end
			end

			if Table.isNotEmpty(substitution.games) then
				local gamesNoun = 'map' .. (#substitution.games > 1 and 's' or '')
				table.insert(subString, string.format('on %s %s', gamesNoun, mw.text.listToText(substitution.games)))
			end

			if String.isNotEmpty(substitution.reason) then
				table.insert(subString, string.format('due to %s', substitution.reason))
			end

			table.insert(comment, table.concat(subString, ' ') .. '.')
		end)
	end)

	if Logic.isEmpty(comment) then return end

	return table.concat(comment, tostring(MatchSummaryWidgets.Break{}))
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

	match:body(CustomMatchSummary.createBody(matchData))

	local substituteComment = MatchSummary.createSubstitutesComment(matchData)

	match:comment(MatchSummaryWidgets.MatchComment{
		children = WidgetUtil.collect(matchData.comment, substituteComment)
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
	assert(type(CustomMatchSummary.createBody) == 'function', 'Function "createBody" missing in "Module:MatchSummary"')

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

---@param vetoData table
---@param options {game: string?, vetoTypeToText:table?, emptyMapDisplay: string?}?
---@return VetoDisplay?
function MatchSummary.defaultMapVetoDisplay(vetoData, options)
	if Logic.isEmpty(vetoData) then
		return
	end

	local mapVeto = MapVeto(options or {})
	Array.forEach(vetoData, function(vetoRound)
		if vetoRound.vetostart then
			mapVeto:vetoStart(tonumber(vetoRound.vetostart), vetoRound.format)
		end
		if vetoRound.type == VETO_DECIDER then
			mapVeto:addDecider(vetoRound.decider)
		else
			mapVeto:addRound(vetoRound.type, vetoRound.team1, vetoRound.team2)
		end
	end)

	return mapVeto
end

---@param games table[]
---@param maxNumberOfBans integer
---@return {[1]: string[], [2]: string[]}[]
function MatchSummary.buildCharacterBanData(games, maxNumberOfBans)
	return Array.map(games, function(game)
		local extradata = game.extradata or {}
		return {
			MatchSummary.buildCharacterList(extradata, 'team1ban', maxNumberOfBans),
			MatchSummary.buildCharacterList(extradata, 'team2ban', maxNumberOfBans),
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
