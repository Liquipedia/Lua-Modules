--- Triple Comment to Enable our LLS Plugin
describe('Standings cells', function()
	local StandingsCells = require('Module:Widget/Standings/Cells')

	---@param slot table
	---@return string
	local function renderPlacement(slot)
		return tostring(StandingsCells.placement(slot))
	end

	it('renders a confirmed placement for a definitive status', function()
		local html = renderPlacement{placement = 1, definitiveStatus = 'up', minimumStatus = 'stay'}
		assert.is_truthy(html:find('data-placement-type="up"', 1, true))
		assert.is_falsy(html:find('data-label-type', 1, true))
	end)

	it('renders a minimum placement for a min status without a definitive status', function()
		local html = renderPlacement{placement = 2, minimumStatus = 'stay'}
		assert.is_truthy(html:find('data-placement-type="stay"', 1, true))
		assert.is_truthy(html:find('data-label-type="placement-minimum"', 1, true))
	end)

	it('renders an undecided placement without any status', function()
		local html = renderPlacement{placement = 3, definitiveStatus = '', minimumStatus = ''}
		assert.is_falsy(html:find('data-placement-type', 1, true))
		assert.is_falsy(html:find('data-label-type', 1, true))
	end)
end)
