---

describe('HTML Widget', function()
	local Widgets = require('Module:Widget/Html/All')

	describe('Abbr', function()
		it('should create an abbr tag', function()
			local abbr = Widgets.Abbr{ children = { "Test" }, title = "Title" }
			local rendered = abbr:render():allDone()
			assert.are.same('<abbr title="Title">Test</abbr>', tostring(rendered))
		end)
	end)

	describe('Div', function()
		it('should create a div tag', function()
			local div = Widgets.Div{ children = { "Content" } }
			local rendered = div:render():allDone()
			assert.are.same('<div>Content</div>', tostring(rendered))
		end)
	end)

	describe('Span', function()
		it('should create a span tag', function()
			local span = Widgets.Span{ children = { "Inline" } }
			local rendered = span:render():allDone()
			assert.are.same('<span>Inline</span>', tostring(rendered))
		end)
	end)

	describe('Table', function()
		it('should create a table tag', function()
			local table = Widgets.Table{ children = { Widgets.Tr{ children = { Widgets.Td{ children = { "Cell" } } } } } }
			local rendered = table:render():allDone()
			assert.are.same('<table><tr><td>Cell</td></tr></table>', tostring(rendered))
		end)
	end)

	describe('Ul & Li', function()
		it('should create a list', function()
			local ul = Widgets.Ul{ children = { Widgets.Li{ children = { "Item" }}, Widgets.Li{ children = { "Item2" }}}}
			local rendered = ul:render():allDone()
			assert.are.same('<ul><li>Item</li><li>Item2</li></ul>', tostring(rendered))
		end)
	end)
end)
