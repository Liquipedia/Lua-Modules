local DateRange = require('Module:Widget/Misc/DateRange')
local I18n = require('Module:I18n')

describe('DateRange Widget', function()
	describe('should return "date-unknown" if startDate is invalid', function()
		it('no startDate', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {}}
			assert.are.equal(I18n.translate('date-unknown'), tostring(widget))
		end)
		it('invalid startDate', function()
			local widget = DateRange{startDate = 'invalid-date'}
			assert.are.equal(I18n.translate('date-unknown'), tostring(widget))
		end)
		it('unknown month', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}}
			assert.are.equal(I18n.translate('date-unknown'), tostring(widget))
		end)
	end)

	it('should return "date-range-month-day--unknown" if endDate is missing', function()
		local widget = DateRange{startDate = {year = 2023, month = 10, day = 1}}
		assert.are.equal(I18n.translate('date-range-month-day--unknown', {
			startMonth = 'Oct', startDate = '01'
		}), tostring(widget))
	end)

	it('should return "date-range-month--unknown" if endDate and startDay is missing',
		function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2023, month = 10}}
			assert.are.equal(I18n.translate('date-range-month--unknown', {
				startMonth = 'Oct'
			}), tostring(widget))
		end
	)

	it('should return "date-range-month" if both days are unknown and in the same month', function()
		---@diagnostic disable-next-line: missing-fields
		local widget = DateRange{startDate = {year = 2023, month = 10}, endDate = {year = 2023, month = 10}}
		assert.are.equal(I18n.translate('date-range-month', {
			startMonth = 'Oct', endMonth = 'Oct',
		}), tostring(widget))
	end)

	it('should return "date-range-month--month" if both days are unknown and in different months',
		function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2023, month = 10}, endDate = {year = 2023, month = 11}}
			assert.are.equal(I18n.translate('date-range-month--month', {
				startMonth = 'Oct', endMonth = 'Nov'
			}), tostring(widget))
		end
	)

	it('should return "date-range-month-day--month-unknown_day" if end day is unknown', function()
	---@diagnostic disable-next-line: missing-fields
		local widget = DateRange{startDate = {year = 2023, month = 10, day = 1}, endDate = {year = 2023, month = 11}}
		assert.are.equal(I18n.translate('date-range-month-day--month-unknown_day', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Nov'
		}), tostring(widget))
	end)

	it('should return "date-range-month-day" if startDate and endDate are the same', function()
		local widget = DateRange{startDate = {year = 2023, month = 10, day = 1}, endDate = {year = 2023, month = 10, day = 1}}
		assert.are.equal(I18n.translate('date-range-month-day', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Oct', endDate = '01'
		}), tostring(widget))
	end)

	it('should return "date-range-month-day--day" if startDate and endDate are in the same month', function()
		local widget = DateRange{
			startDate = {year = 2023, month = 10, day = 1},
			endDate = {year = 2023, month = 10, day = 10}
		}
		assert.are.equal(I18n.translate('date-range-month-day--day', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Oct', endDate = '10'
		}), tostring(widget))
	end)

	it('should return "date-range-month-day--month-day" if startDate and endDate are in different months', function()
		local widget = DateRange{
			startDate = {year = 2023, month = 10, day = 1},
			endDate = {year = 2023, month = 11, day = 10}
		}
		assert.are.equal(I18n.translate('date-range-month-day--month-day', {
			startMonth = 'Oct', startDate = '01', endMonth = 'Nov', endDate = '10'
		}), tostring(widget))
	end)

	describe('with showYear', function()
		it('no startDate', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {}, showYear = true}
			assert.are.equal(I18n.translate('date-unknown'), tostring(widget))
		end)
		it('invalid startDate', function()
			local widget = DateRange{startDate = 'invalid-date', showYear = true}
			assert.are.equal(I18n.translate('date-unknown'), tostring(widget))
		end)
		it('unknown startMonth, no endDate', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year--unknown', {
				startYear = '2024'
			}), tostring(widget))
		end)
		it('unknown startDay, no endDate', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024, month = 10}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year-month--unknown', {
				startYear = '2024', startMonth = 'Oct'
			}), tostring(widget))
		end)
		it('known startDate, no endDate', function()
			local widget = DateRange{startDate = {year = 2024, month = 10, day = 3}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year-month-day--unknown', {
				startYear = '2024', startMonth = 'Oct', startDate = '03'
			}), tostring(widget))
		end)

		it('known startYear, known, different endYear', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, endDate = {year = 2025}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year--year', {
				startYear = '2024', endYear = '2025'
			}), tostring(widget))
		end)

		it('known startYear, different endYear, known endMonth', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, endDate = {year = 2025, month = 10}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year--year', {
				startYear = '2024', endYear = '2025', endMonth = 'Oct'
			}), tostring(widget))
		end)

		it('known startYear, different endYear, known endMonth, known endDay', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, endDate = {year = 2025, month = 10, day = 3}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year--year', {
				startYear = '2024', endYear = '2025', endMonth = 'Oct', endDate = '03'
			}), tostring(widget))
		end)

		it('known startYear, known, same endYear', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, endDate = {year = 2024}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year', {
				startYear = '2024'
			}), tostring(widget))
		end)

		it('known startYear, same endYear, known endMonth', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, endDate = {year = 2024, month = 10}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year', {
				startYear = '2024', endYear = '2024', endMonth = 'Oct'
			}), tostring(widget))
		end)

		it('known startYear, same endYear, known endMonth, known endDay', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024}, endDate = {year = 2024, month = 10, day = 3}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year', {
				startYear = '2024', endYear = '2024', endMonth = 'Oct', endDate = '03'
			}), tostring(widget))
		end)

		it('known startYear, startMonth, different endYear', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024, month = 10}, endDate = {year = 2025}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year-month--year-unknown_month', {
				startYear = '2024', startMonth = 'Oct', endYear = '2025'
			}), tostring(widget))
		end)

		it('known startYear, startMonth, same endYear', function()
			---@diagnostic disable-next-line: missing-fields
			local widget = DateRange{startDate = {year = 2024, month = 10}, endDate = {year = 2024}, showYear = true}
			assert.are.equal(I18n.translate('date-range-year-month--unknown_month', {
				startYear = '2024', startMonth = 'Oct', endYear = '2024'
			}), tostring(widget))
		end)
	end)
end)
