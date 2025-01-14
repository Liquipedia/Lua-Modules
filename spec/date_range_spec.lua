local DateRange = require('Module:Widget/Misc/DateRange')
local I18n = require('Module:I18n')

describe('DateRange Widget', function()
	describe('should return "date-unknown" if startDate is invalid', function()
		it('no startDate', function()
			local widget = DateRange{startDate = {}}
			assert.are.equal(I18n.translate('date-unknown'), widget:render())
		end)
		it('invalid startDate', function()
			local widget = DateRange{startDate = 'invalid-date'}
			assert.are.equal(I18n.translate('date-unknown'), widget:render())
		end)
		it('unknown month', function()
			local widget = DateRange{startDate = {year = 2024}}
			assert.are.equal(I18n.translate('date-unknown'), widget:render())
		end)
	end)

	it('should return "date-range-different-months-unknown-end" if endDate is missing', function()
		local widget = DateRange{startDate = {year = 2023, month = 10, day = 1}}
		assert.are.equal(I18n.translate('date-range-different-months-unknown-end', {
			startMonth = 'Oct', startDate = '01'
		}), widget:render())
	end)

	it('should return "date-range-different-months-unknown-days-and-end-month" if endDate and startDay is missing',
		function()
			local widget = DateRange{startDate = {year = 2023, month = 10}}
			assert.are.equal(I18n.translate('date-range-different-months-unknown-days-and-end-month', {
				startMonth = 'Oct'
			}), widget:render())
		end
	)

	it('should return "date-range-same-month-unknown-days" if both days are unknown and in the same month', function()
		local widget = DateRange{startDate = {year = 2023, month = 10}, endDate = {year = 2023, month = 10}}
		assert.are.equal(I18n.translate('date-range-same-month-unknown-days', {
			startMonth = 'Oct', endMonth = 'Oct',
		}), widget:render())
	end)

	it('should return "date-range-different-months-unknown-days" if both days are unknown and in different months',
		function()
			local widget = DateRange{startDate = {year = 2023, month = 10}, endDate = {year = 2023, month = 11}}
			assert.are.equal(I18n.translate('date-range-different-months-unknown-days', {
				startMonth = 'Oct', endMonth = 'Nov'
			}), widget:render())
		end
	)

	it('should return "date-range-different-months-unknown-end-day" if end day is unknown', function()
		local widget = DateRange{startDate = {year = 2023, month = 10, day = 1}, endDate = {year = 2023, month = 11}}
		assert.are.equal(I18n.translate('date-range-different-months-unknown-end-day', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Nov'
		}), widget:render())
	end)

	it('should return "date-range-same-day" if startDate and endDate are the same', function()
		local widget = DateRange{startDate = {year = 2023, month = 10, day = 1}, endDate = {year = 2023, month = 10, day = 1}}
		assert.are.equal(I18n.translate('date-range-same-day', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Oct', endDate = '01'
		}), widget:render())
	end)

	it('should return "date-range-same-month" if startDate and endDate are in the same month', function()
		local w = DateRange{startDate = {year = 2023, month = 10, day = 1}, endDate = {year = 2023, month = 10, day = 10}}
		assert.are.equal(I18n.translate('date-range-same-month', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Oct', endDate = '10'
		}), w:render())
	end)

	it('should return "date-range-different-months" if startDate and endDate are in different months', function()
		local w = DateRange{startDate = {year = 2023, month = 10, day = 1}, endDate = {year = 2023, month = 11, day = 10}}
		assert.are.equal(I18n.translate('date-range-different-months', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Nov', endDate = '10'
		}), w:render())
	end)
end)
