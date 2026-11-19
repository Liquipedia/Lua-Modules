--- Triple Comment to Enable our LLS Plugin
describe('MedalsTable', function()
	local MedalsTable = require('Module:Widget/MedalsTable')

	---@param collapseAfter integer?
	---@return string
	local function render(collapseAfter)
		return tostring(MedalsTable{
			data = {a = {total = 3}, b = {total = 2}, c = {total = 1}},
			dataColumns = {'total'},
			hideTotalRow = true,
			renderRowFirstCell = function(key) return key end,
			collapseAfter = collapseAfter,
		})
	end

	it('collapses the rows after collapseAfter and is not sortable', function()
		local html = render(2)
		assert.is_truthy(html:find('general-collapsible collapsed', 1, true))
		assert.are_equal(1, select(2, html:gsub('table2__row%-%-hide%-on%-collapse', '')))
		assert.is_falsy(html:find('sortable', 1, true))
	end)

	it('does not collapse when no row is after collapseAfter', function()
		local html = render(3)
		assert.is_falsy(html:find('general-collapsible', 1, true))
		assert.is_truthy(html:find('sortable', 1, true))
	end)
end)
