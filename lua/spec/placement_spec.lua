--- Triple Comment to Enable our LLS Plugin
describe('placement', function()
	local Placement = require('Module:Placement')

	local NON_BREAKING_SPACE = '&nbsp;'
	local ZERO_WIDTH_SPACE = '&#8203;'
	local EN_DASH = '–'

	describe('range', function()
		it('check', function()
			local DASH = ZERO_WIDTH_SPACE .. EN_DASH .. ZERO_WIDTH_SPACE
			assert.are_equal(('1st' .. DASH .. '2nd'), Placement.RangeLabel{1, 2})
			assert.are_equal('1st', Placement.RangeLabel{1, 1})
		end)
	end)

	describe('bg class', function()
		it('check', function()
			assert.is_nil(Placement.getBgClass{placement = 'DummyDummy'})
			assert.are_equal('background-color-first-place', Placement.getBgClass{placement = 1})
			assert.are_equal('bg-dq', Placement.getBgClass{placement = 'dq'})
		end)
	end)

	describe('get', function()
		it('check', function()
			local DASH = NON_BREAKING_SPACE .. '-' .. NON_BREAKING_SPACE
			assert.are_equal(
				'class="text-center placement-1" data-sort-value="1"|<b class="placement-text">1st</b>',
				Placement.get{placement = '1'}
			)
			assert.are_equal(
				'class="text-center placement-3" data-sort-value="3-4"|<b class="placement-text">3rd' ..
				DASH .. '4th</b>',
				Placement.get{placement = '3-4'}
			)
			assert.are_equal(
				'class="text-center placement-dnp" data-sort-value="1032"|<b>hi</b>',
				Placement.get{placement = 'dnp', customText = 'hi'}
			)
		end)
	end)
end)
