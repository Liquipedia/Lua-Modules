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
				'class="text-center" data-sort-value="1"|<span class="placement-box placement-1">' ..
				'<b class="placement-text">1st</b></span>',
				Placement.get{placement = '1'}
			)
			assert.are_equal(
				'class="text-center" data-sort-value="3-4"|<span class="placement-box placement-3"><b class="placement-text">3rd' ..
				DASH .. '4th</b></span>',
				Placement.get{placement = '3-4'}
			)
			assert.are_equal(
				'class="text-center" data-sort-value="1032"|<span class="placement-box placement-dnp"><b>hi</b></span>',
				Placement.get{placement = 'dnp', customText = 'hi'}
			)
		end)
	end)
end)
