---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Html/All
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Widgets = {}

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Widget = Lua.import('Module:Widget')

---@param tag? string
---@param specialMapping? fun(self: WidgetHtml)
---@return WidgetHtml
local function createHtmlTag(tag, specialMapping)
	---@class WidgetHtml: Widget
	---@operator call(table): WidgetHtml
	local Html = Class.new(Widget)
	Html.defaultProps = {
		classes = {},
		css = {},
		attributes = {},
		tag = tag,
	}

	---@return Html
	function Html:render()
		if specialMapping then
			specialMapping(self)
		end
		local htmlNode = mw.html.create(self.props.tag)

		htmlNode:addClass(String.nilIfEmpty(table.concat(self.props.classes, ' ')))
		htmlNode:css(self.props.css)
		htmlNode:attr(self.props.attributes)

		Array.forEach(self.props.children, function(child)
			if Class.instanceOf(child, Widget) then
				---@cast child Widget
				child.context = self:_nextContext()
				htmlNode:node(child:tryMake())
			else
				---@cast child -Widget
				---@diagnostic disable-next-line: undefined-field
				if type(child) == 'table' and not child._build then
					mw.log('ERROR! Bad child input:' .. mw.dumpObject(self.props.children))
					-- Erroring here to make it easier to debug
					-- Otherwise it will fail when the html is built
					error('Table passed to HtmlBase:renderAs() without _build method')
				end
				htmlNode:node(child)
			end
		end)
		return htmlNode
	end

	return Html
end

Widgets.Abbr = createHtmlTag('abbr', function (self)
	self.props.attributes.title = self.props.attributes.title or self.props.title
end)
Widgets.Aside = createHtmlTag('aside')
Widgets.B = createHtmlTag('b')
Widgets.Bdi = createHtmlTag('bdi')
Widgets.Bdo = createHtmlTag('bdo')
Widgets.Big = createHtmlTag('big')
Widgets.Blockquote = createHtmlTag('blockquote')
Widgets.Br = createHtmlTag('br')
Widgets.Caption = createHtmlTag('caption')
Widgets.Center = createHtmlTag('center')
Widgets.Cite = createHtmlTag('cite')
Widgets.Code = createHtmlTag('code')
Widgets.Col = createHtmlTag('col')
Widgets.Colgroup = createHtmlTag('colgroup')
Widgets.Data = createHtmlTag('data')
Widgets.Dd = createHtmlTag('dd')
Widgets.Del = createHtmlTag('del')
Widgets.Dfn = createHtmlTag('dfn')
Widgets.Div = createHtmlTag('div')
Widgets.Dl = createHtmlTag('dl')
Widgets.Dt = createHtmlTag('dt')
Widgets.Em = createHtmlTag('em')
Widgets.Figcaption = createHtmlTag('figcaption')
Widgets.Figure = createHtmlTag('figure')
Widgets.Font = createHtmlTag('font')
Widgets.Fragment = createHtmlTag(nil)
Widgets.H1 = createHtmlTag('h1')
Widgets.H2 = createHtmlTag('h2')
Widgets.H3 = createHtmlTag('h3')
Widgets.H4 = createHtmlTag('h4')
Widgets.H5 = createHtmlTag('h5')
Widgets.H6 = createHtmlTag('h6')
Widgets.Hr = createHtmlTag('hr')
Widgets.I = createHtmlTag('i')
Widgets.Ins = createHtmlTag('ins')
Widgets.Kbd = createHtmlTag('kbd')
Widgets.Li = createHtmlTag('li')
Widgets.Mark = createHtmlTag('mark')
Widgets.Ol = createHtmlTag('ol')
Widgets.P = createHtmlTag('p')
Widgets.Pre = createHtmlTag('pre')
Widgets.Q = createHtmlTag('q')
Widgets.S = createHtmlTag('s')
Widgets.Samp = createHtmlTag('samp')
Widgets.Small = createHtmlTag('small')
Widgets.Span = createHtmlTag('span')
Widgets.Strike = createHtmlTag('strike')
Widgets.Strong = createHtmlTag('strong')
Widgets.Sub = createHtmlTag('sub')
Widgets.Sup = createHtmlTag('sup')
Widgets.Table = createHtmlTag('table')
Widgets.Tbody = createHtmlTag('tbody')
Widgets.Td = createHtmlTag('td')
Widgets.Tfoot = createHtmlTag('tfoot')
Widgets.Th = createHtmlTag('th')
Widgets.Thead = createHtmlTag('thead')
Widgets.Time = createHtmlTag('time')
Widgets.Tr = createHtmlTag('tr')
Widgets.Tt = createHtmlTag('tt')
Widgets.U = createHtmlTag('u')
Widgets.Ul = createHtmlTag('ul')
Widgets.Var = createHtmlTag('var')
Widgets.Wbr = createHtmlTag('wbr')

return Widgets
