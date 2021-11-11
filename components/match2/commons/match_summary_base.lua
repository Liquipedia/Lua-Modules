---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

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
	self.leftScore = content
		:css('border-right', '1px solid #aaa')
		:css('text-align', 'left')
		:css('width','24px')
	return self
end

function Header:rightScore(content)
	self.rightScore = content
		:css('border-left', '1px solid #aaa')
		:css('text-align', 'right')
		:css('width','24px')
	return self
end

function Header:rightOpponent(content)
	self.rightElement = content
	return self
end

function Header:create()
	self.root:tag('div')
		:addClass('brkts-popup-header-opponent'):css('display', 'flex'):css('justify-content', 'flex-end')
		:node(self.leftElement)
		:node(self.leftScore or '')
	self.root:tag('div')
		:addClass('brkts-popup-header-opponent'):css('display', 'flex'):css('justify-content', 'flex-start')
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
		self.inner:addClass('brkts-popup-spaced')
	end
)

function Footer:addElement(element)
	self.inner:node(element)
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

function MatchSummary:comment(comment)
	self.commentElement = comment:create()
	return self
end

function MatchSummary:footer(footer)
	self.footerElement = footer:create()
	return self
end

function MatchSummary:create()
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

return MatchSummary
