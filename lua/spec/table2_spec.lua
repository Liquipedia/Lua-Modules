--- Triple Comment to Enable our LLS Plugin
describe('Table2', function()
	local TableWidgets = require('Module:Widget/Table2/All')
	local Array = require('Module:Array')

	---@param names string[]
	---@return Widget
	local function body(names)
		return TableWidgets.TableBody{children = Array.map(names, function(name)
			return TableWidgets.Row{children = {TableWidgets.Cell{children = name}}}
		end)}
	end

	---@param html string
	---@return string[]
	local function hiddenRows(html)
		local names = {}
		for row in html:gmatch('<tr class="[^"]*table2__row%-%-hide%-on%-collapse[^"]*".-</tr>') do
			table.insert(names, row:match('<td[^>]*>([^<]*)</td>'))
		end
		return names
	end

	describe('collapseAfter', function()
		it('collapses the rows of each body after the first ones behind a footer toggle', function()
			local html = tostring(TableWidgets.Table{
				collapseAfter = 2,
				expandText = 'Show all',
				collapseText = 'Hide some',
				children = {body{'A1', 'A2', 'A3'}, body{'B1', 'B2', 'B3', 'B4'}},
			})
			assert.is_truthy(html:find('class="table2 table2--generic general-collapsible collapsed"', 1, true))
			assert.are_same({'A3', 'B3', 'B4'}, hiddenRows(html))
			assert.is_truthy(html:find(
				'<div class="table2__footer"><div class="table2__collapse-toggle" data-collapsible-click-region="true">',
				1, true
			))
			assert.is_truthy(html:find('Show all', 1, true))
			assert.is_truthy(html:find('Hide some', 1, true))
		end)

		it('labels the toggle by default', function()
			local html = tostring(TableWidgets.Table{collapseAfter = 1, children = {body{'A1', 'A2'}}})
			assert.is_truthy(html:find('Show more', 1, true))
			assert.is_truthy(html:find('Show less', 1, true))
		end)

		it('keeps the footer next to the toggle', function()
			local html = tostring(TableWidgets.Table{
				collapseAfter = 1,
				footer = 'Footnote',
				children = {body{'A1', 'A2'}},
			})
			assert.is_truthy(html:find('<div class="table2__footer">Footnote<div class="table2__collapse-toggle"', 1, true))
		end)

		it('does nothing without it', function()
			local html = tostring(TableWidgets.Table{children = {body{'A1', 'A2'}}})
			assert.is_falsy(html:find('collapse', 1, true))
			assert.is_falsy(html:find('table2__footer', 1, true))
		end)

		it('counts the rows of components and nested arrays, but not subheaders', function()
			local Component = require('Module:Widget/Component')
			local RowComponent = Component.component(function(props)
				return TableWidgets.Row{children = {TableWidgets.Cell{children = props.name}}}
			end)
			local html = tostring(TableWidgets.Table{
				collapseAfter = 2,
				children = {TableWidgets.TableBody{children = {
					TableWidgets.Row{section = 'subhead', children = {TableWidgets.CellHeader{children = 'Sub'}}},
					RowComponent{name = 'A1'},
					{RowComponent{name = 'A2'}, RowComponent{name = 'A3'}},
					RowComponent{name = 'A4'},
				}}},
			})
			assert.are_same({'A3', 'A4'}, hiddenRows(html))
		end)

		it('does not keep the cut of a reused body', function()
			local reusedBody = body{'A1', 'A2', 'A3'}
			assert.are_same({'A2', 'A3'}, hiddenRows(tostring(TableWidgets.Table{collapseAfter = 1, children = {reusedBody}})))
			assert.are_same({'A3'}, hiddenRows(tostring(TableWidgets.Table{collapseAfter = 2, children = {reusedBody}})))
			assert.are_same({}, hiddenRows(tostring(TableWidgets.Table{children = {reusedBody}})))
		end)

		it('does not apply to a table nested in a cell', function()
			local html = tostring(TableWidgets.Table{
				collapseAfter = 1,
				children = {TableWidgets.TableBody{children = {
					TableWidgets.Row{children = {TableWidgets.Cell{children = TableWidgets.Table{
						children = {body{'N1', 'N2'}},
					}}}},
				}}},
			})
			assert.are_same({}, hiddenRows(html))
		end)

		it('does not count the body rows of a nested table without a body', function()
			local nestedTable = TableWidgets.Table{children = {
				TableWidgets.Row{section = 'body', children = {TableWidgets.Cell{children = 'N1'}}},
			}}
			local html = tostring(TableWidgets.Table{
				collapseAfter = 2,
				children = {TableWidgets.TableBody{children = {
					TableWidgets.Row{children = {TableWidgets.Cell{children = nestedTable}}},
					TableWidgets.Row{children = {TableWidgets.Cell{children = 'A2'}}},
					TableWidgets.Row{children = {TableWidgets.Cell{children = 'A3'}}},
				}}},
			})
			assert.are_same({'A3'}, hiddenRows(html))
		end)
	end)
end)
