---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay


---@class MatchSummaryBreak
---@operator call: MatchSummaryBreak
---@field root Html
local Break = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-break')
	end
)

---@return Html
function Break:create()
	return self.root
end

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

---@class MatchSummaryRow
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

---@param element Html
---@return MatchSummaryRow
function Row:addElement(element)
	table.insert(self.elements, element)
	return self
end

---@return Html
function Row:create()
	for _, element in pairs(self.elements) do
		self.root:node(element)
	end

	return self.root
end

---@class MatchSummaryMvp
---@operator call: MatchSummaryMvp
---@field root Html
---@field players Html[]
local Mvp = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-footer'):addClass('brkts-popup-mvp')
		self.players = {}
	end
)

---@param player table
---@return MatchSummaryMvp
function Mvp:addPlayer(player)
	local playerDisplay
	if Logic.isEmpty(player) then
		return self
	elseif type(player) == 'table' then
		playerDisplay = '[[' .. player.name .. '|' .. player.displayname .. ']]'
		if player.comment then
			playerDisplay = playerDisplay .. ' (' .. player.comment .. ')'
		end
	else
		playerDisplay = '[[' .. player .. ']]'
	end

	table.insert(self.players, playerDisplay)

	return self
end

---@param points number
---@return MatchSummaryMvp
function Mvp:setPoints(points)
	if Logic.isNumeric(points) then
		self.points = points
	end
	return self
end

---@return Html
function Mvp:create()
	local span = mw.html.create('span')
	span:wikitext(#self.players > 1 and 'MVPs: ' or 'MVP: ')
		:wikitext(table.concat(self.players, ', '))
	if self.points and self.points ~= 1 then
		span:wikitext(' ('.. self.points ..'pts)')
	end
	self.root:node(span)
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

---@param row MatchSummaryRow
---@return MatchSummaryBody
---@overload fun(any): MatchSummaryBody #for Mvp, Casters and wiki custom classes to be put into `:addRow`
function Body:addRow(row)
	self.root:node(row:create())
	return self
end

---@return Html
function Body:create()
	return self.root
end

---@class MatchSummaryComment
---@operator call: MatchSummaryComment
---@field root Html
local Comment = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-comment')
			:css('white-space', 'normal')
			:css('font-size', '85%')
	end
)

---@param content Html|string|number
---@return MatchSummaryComment
function Comment:content(content)
	self.root:node(content):node(Break():create())
	return self
end

---@return Html
function Comment:create()
	return self.root
end

---@class MatchSummaryFooter
---@operator call: MatchSummaryFooter
---@field root Html
---@field inner Html
---@field elements (Html|string)[]
local Footer = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-footer')
		self.inner = mw.html.create('div')
			:addClass('brkts-popup-spaced vodlink')
		self.elements = {}
	end
)

---@param element Html
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

---@param linkData table<string, {icon: string, text: string, iconDark: string?}>
---@param links table<string, string>
---@return MatchSummaryFooter
function Footer:addLinks(linkData, links)
	for linkType, link in pairs(links) do
		local currentLinkData = linkData[linkType]
		if not currentLinkData then
			mw.log('Unknown link: ' .. linkType)
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

---MatchSummary Casters Class
---@class MatchSummaryCasters
---@operator call: MatchSummaryCasters
---@field root Html
---@field casters string[]
local Casters = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-comment')
			:css('white-space','normal')
			:css('font-size','85%')
		self.casters = {}
	end
)

---adds a casters display to thge casters list
---@param caster {name: string, displayName: string, flag: string?}?
---@return MatchSummaryCasters
function Casters:addCaster(caster)
	if Logic.isNotEmpty(caster) then
		---@cast caster -nil
		local nameDisplay = '[[' .. caster.name .. '|' .. caster.displayName .. ']]'
		if caster.flag then
			table.insert(self.casters, Flags.Icon(caster.flag) .. '&nbsp;' .. nameDisplay)
		else
			table.insert(self.casters, nameDisplay)
		end
	end

	return self
end

---creates the casters display
---@return Html
function Casters:create()
	return self.root
		:wikitext('Caster' .. (#self.casters > 1 and 's' or '') .. ': ')
		:wikitext(mw.text.listToText(self.casters, ', ', ' & '))
end

---@class MatchSummaryMatch
---@operator call: MatchSummaryMatch
---@field root Html
---@field headerElement Html?
---@field bodyElement Html?
---@field commentElement Html?
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

---@param body MatchSummaryBody
---@return MatchSummaryMatch
function Match:body(body)
	self.bodyElement = body:create()
	return self
end

---@param comment MatchSummaryComment
---@return MatchSummaryMatch
function Match:comment(comment)
	self.commentElement = comment:create()
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
		:node(Break():create())
		:node(self.bodyElement)
		:node(Break():create())

	if self.commentElement ~= nil then
		self.root
			:node(self.commentElement)
			:node(Break():create())
	end

	if self.footerElement ~= nil then
		self.root:node(self.footerElement)
	end

	return self.root
end

---@class MatchSummary
---@field Header MatchSummaryHeader
---@field Body MatchSummaryBody
---@field Comment MatchSummaryComment
---@field Row MatchSummaryRow
---@field Footer MatchSummaryFooter
---@field Break MatchSummaryBreak
---@field Mvp MatchSummaryMvp
---@field Casters MatchSummaryCasters
---@field Match MatchSummaryMatch
---@field matches Html[]?
---@field headerElement Html?
---@field root Html?
local MatchSummary = Class.new()
MatchSummary.Header = Header
MatchSummary.Body = Body
MatchSummary.Comment = Comment
MatchSummary.Row = Row
MatchSummary.Footer = Footer
MatchSummary.Break = Break
MatchSummary.Mvp = Mvp
MatchSummary.Casters = Casters
MatchSummary.Match = Match

---@param width string
---@return MatchSummary
function MatchSummary:init(width)
	self.matches = {}
	self.root = mw.html.create('div')
		:addClass('brkts-popup')
		:css('width', width)
	return self
end

---@param header MatchSummaryHeader
---@return MatchSummary
function MatchSummary:header(header)
	self.headerElement = header:create()
	return self
end

---@param match MatchSummaryMatch
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
---@param options {noScore: boolean?}?
---@return MatchSummaryHeader
function MatchSummary.createDefaultHeader(match, options)
	options = options or {}

	local header = MatchSummary.Header()

	if options.noScore then
		return header
			:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
			:rightOpponent(header:createOpponent(match.opponents[2], 'right'))
	end

	return header
		:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(match.opponents[1]))
		:rightScore(header:createScore(match.opponents[2]))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))
end

---Creates a match footer with vods if vods are set
---@param match table
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function MatchSummary.addVodsToFooter(match, footer)
	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	if match.vod then
		footer:addElement(VodLink.display{
			vod = match.vod,
		})
	end
	for index, vod in pairs(vods) do
		footer:addElement(VodLink.display{
			gamenum = index,
			vod = vod,
		})
	end

	return footer
end

---Default createMatch function for usage in Custom MatchSummary
---@param matchData table
---@param CustomMatchSummary table
---@return MatchSummaryMatch?
function MatchSummary.createMatch(matchData, CustomMatchSummary)
	if not matchData then
		return
	end

	local match = Match()

	local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
	match:header(createHeader(matchData))

	match:body(CustomMatchSummary.createBody(matchData))

	if matchData.comment then
		local comment = MatchSummary.Comment():content(matchData.comment)
		match:comment(comment)
	end
	local createFooter = CustomMatchSummary.addToFooter or MatchSummary.addVodsToFooter
	match:footer(createFooter(matchData, MatchSummary.Footer()))

	return match
end

---Default getByMatchId function for usage in Custom MatchSummary
---@param CustomMatchSummary table
---@param args table
---@return Html
function MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
	assert(type(CustomMatchSummary.createBody) == 'function', 'Function "createBody" missing in "Module:MatchSummary"')

	local match, bracketResetMatch = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()

	--additional header for when martin adds the the css and buttons for switching between match and reset match
	--if bracketResetMatch then
		--local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
		--matchSummary:header(createHeader(match, {noScore = true}))
		--here martin can add the buttons for switching between match and reset match
	--end

	local createMatch = CustomMatchSummary.createMatch or function(matchData)
		return MatchSummary.createMatch(matchData, CustomMatchSummary)
	end
	matchSummary:addMatch(createMatch(match))
	matchSummary:addMatch(createMatch(bracketResetMatch))

	return matchSummary:create()
end

return MatchSummary
