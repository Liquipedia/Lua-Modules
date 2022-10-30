---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')

local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local Break = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-break')
	end
)

function Break:create()
	return self.root
end

local Header = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-header-dev')
		self.root:css('justify-content', 'center')
	end
)

function Header:leftOpponent(content)
	self.leftElement = content
	return self
end

function Header:leftScore(content)
	self.leftScore = content:addClass('brkts-popup-header-opponent-score-left')
	return self
end

function Header:rightScore(content)
	self.rightScore = content:addClass('brkts-popup-header-opponent-score-right')
	return self
end

function Header:rightOpponent(content)
	self.rightElement = content
	return self
end

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

function Header:create()
	self.root:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-left')
		:node(self.leftElement)
		:node(self.leftScore or '')
	self.root:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-right')
		:node(self.rightScore or '')
		:node(self.rightElement)
	return self.root
end

local Row = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-body-element')
		self.elements = {}
	end
)

function Row:addClass(class)
	self.root:addClass(class)
	return self
end

function Row:css(name, value)
	self.root:css(name, value)
	return self
end

function Row:addElement(element)
	table.insert(self.elements, element)
	return self
end

function Row:create()
	for _, element in pairs(self.elements) do
		self.root:node(element)
	end

	return self.root
end

local Mvp = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-footer'):addClass('brkts-popup-mvp')
		self.players = {}
	end
)

function Mvp:addPlayer(player)
	if Logic.isEmpty(player) then
		return self
	elseif type(player) == 'table' then
		table.insert(self.players, player.name .. '|' .. player.displayname)
	else
		table.insert(self.players, player)
	end
	return self
end

function Mvp:setPoints(points)
	if Logic.isNumeric(points) then
		self.points = points
	end
	return self
end

function Mvp:addFreeText(freeText)
	if String.isNotEmpty(freeText) then
		self.freeText = freeText
	end
	return self
end

function Mvp:create()
	local span = mw.html.create('span')
	span:wikitext(#self.players > 1 and 'MVPs: ' or 'MVP: ')
	for index, player in ipairs(self.players) do
		if index > 1 then
			span:wikitext(', ')
		end
		span:wikitext('[['..player..']]')
	end
	if self.points and self.points ~= 1 then
		span:wikitext(' ('.. self.points ..'pts)')
	end
	if self.freeText then
		span:wikitext(' ('.. self.freeText ..')')
	end
	self.root:node(span)
	return self.root
end

local Body = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-body')
	end
)

function Body:addRow(row)
	self.root:node(row:create())
	return self
end

function Body:create()
	return self.root
end

local Comment = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root
			:addClass('brkts-popup-comment')
			:css('white-space', 'normal')
			:css('font-size', '85%')
	end
)

function Comment:content(content)
	self.root:node(content):node(Break():create())
	return self
end

function Comment:create()
	return self.root
end

local Footer = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-footer')
		self.inner = mw.html.create('div')
		self.inner:addClass('brkts-popup-spaced vodlink')
	end
)

function Footer:addElement(element)
	self.inner:node(element)
	return self
end

function Footer:addLink(link, icon, iconDark, text)
	local content
	if String.isEmpty(iconDark) then
		content = '[['..icon..'|link='..link..'|15px|'..text..'|alt=' .. link .. ']]'
	else
		content = '[['..icon..'|link='..link..'|15px|'..text..'|alt=' .. link .. '|class=show-when-light-mode]]'
			.. '[['..iconDark..'|link='..link..'|15px|'..text..'|alt=' .. link .. '|class=show-when-dark-mode]]'
	end

	self.inner:wikitext(content)
	return self
end

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

function Footer:create()
	self.root:node(self.inner)
	return self.root
end

local MatchSummary = Class.new()
MatchSummary.Header = Header
MatchSummary.Body = Body
MatchSummary.Comment = Comment
MatchSummary.Row = Row
MatchSummary.Footer = Footer
MatchSummary.Break = Break
MatchSummary.Mvp = Mvp

function MatchSummary:init(width)
	self.root = mw.html.create('div')
	self.root
		:addClass('brkts-popup')
		:css('width', width)
	return self
end

function MatchSummary:header(header)
	self.headerElement = header:create()
	return self
end

function MatchSummary:body(body)
	self.bodyElement = body:create()
	return self
end

function MatchSummary:resetBody(resetBody)
	self.resetBodyElement = resetBody:create()
	return self
end

function MatchSummary:resetHeader(resetHeader)
	self.resetHeader = resetHeader:create()
		:addClass('brkts-popup-header-reset')
	return self
end

function MatchSummary:comment(comment)
	self.commentElement = comment:create()
	return self
end

function MatchSummary:footer(footer)
	self.footerElement = footer:create()
	return self
end

function MatchSummary._fallbackResetHeader()
	return mw.html.create('div')
		:addClass('brkts-popup-body-element brkts-popup-header-reset')
		:css('margin','auto')
		:css('font-weight', 'bold')
		:wikitext('Reset match')
end

function MatchSummary:create()
	self.root
		:node(self.headerElement)
		:node(Break():create())
		:node(self.bodyElement)
		:node(Break():create())

	if self.resetBodyElement then
		self.root
			:node(self.resetHeader or MatchSummary._fallbackResetHeader())
			:node(Break():create())
			:node(self.resetBodyElement)
			:node(Break():create())
	end

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

return MatchSummary
