--- Triple Comment to Enable our LLS Plugin
describe('i18n', function ()
	local I18n = require('Module:I18n')

	describe('translate', function()
		it('returns the correct interpolated string for an existing key', function()
			local data = { round = 7 }
			local result = I18n.translate('brkts-header-rx', data)
			assert.are.equal('Round 7,R7', result)
		end)

		it('returns the placeholder string for a missing key', function()
			local data = { round = 1 }
			local result = I18n.translate('nonexistent_key', data)
			assert.are.equal('⧼nonexistent_key⧽', result)
		end)

		it('falls back to English if the key is not found in the current language', function()
			local data = { round = 7 }
			local languageStub = stub(mw.language.getContentLanguage(), 'getCode', 'es')

			local result = I18n.translate('brkts-header-rx', data)
			assert.are.equal('Round 7,R7', result)

			languageStub:revert()
		end)
	end)

	describe('date formats with year', function ()
		local data = {
			startYear = '2024', startMonth = 'Oct', startDate = '03',
			endYear = '2025', endMonth = 'Nov', endDate = '04',
		}

		it('Prints an unknown date', function ()
			assert.are.equal('TBA', I18n.translate('date-unknown', data))
			assert.are.equal('TBA', I18n.translate('date-range-unknown', data))
		end)

		it('Confirmed startYear', function ()
			assert.are.equal('2024', I18n.translate('date-range-year', data))
			assert.are.equal('2024 - TBA', I18n.translate('date-range-year--unknown', data))
			assert.are.equal('2024 - 2025', I18n.translate('date-range-year--year', data))
		end)

		it('Confirmed startYear, startMonth', function ()
			assert.are.equal('Oct, 2024', I18n.translate('date-range-year-month', data))
			assert.are.equal('Oct - Nov, 2024', I18n.translate('date-range-year-month--month', data))
			assert.are.equal('Oct, 2024 - Nov, 2025', I18n.translate('date-range-year-month--year-month', data))
			assert.are.equal('Oct, 2024 - TBA', I18n.translate('date-range-year-month--unknown', data))
			assert.are.equal('Oct, 2024 - TBA, 2025', I18n.translate('date-range-year-month--year-unknown_month', data))
			assert.are.equal('Oct - TBA, 2024', I18n.translate('date-range-year-month--unknown_month', data))
		end)

		it('Confirmed startYear, startMonth, startDay', function ()
			assert.are.equal('Oct 03, 2024', I18n.translate('date-range-year-month-day', data))
			assert.are.equal('Oct 03, 2024 - TBA', I18n.translate('date-range-year-month-day--unknown', data))
			assert.are.equal('Oct 03, 2024 - TBA, 2025', I18n.translate('date-range-year-month-day--year-unknown_month', data))
			assert.are.equal(
				'Oct 03, 2024 - Nv TBA, 2025',
				I18n.translate('date-range-year-month-day--year-month-unknown_day', data)
			)
			assert.are.equal('Oct 03, 2024 - Nov 04, 2025', I18n.translate('date-range-year-month-day--year-month-day', data))
			assert.are.equal('Oct 03 - Nov 04, 2024', I18n.translate('date-range-year-month-day--month-day', data))
			assert.are.equal('Oct 03 - Nov TBA, 2024', I18n.translate('date-range-year-month-day--month-unknown_day', data))
			assert.are.equal('Oct 03 - 04, 2024', I18n.translate('date-range-year-month-day--day', data))
		end)
	end)

	describe('date formats without year', function ()
		local data = {
			startYear = '2024', startMonth = 'Oct', startDate = '03',
			endYear = '2025', endMonth = 'Nov', endDate = '04',
		}

		it('Confirmed startMonth', function ()
			assert.are.equal('Oct', I18n.translate('date-range-month', data))
			assert.are.equal('Oct - TBA', I18n.translate('date-range-month--unknown_month', data))
			assert.are.equal('Oct - Nov', I18n.translate('date-range-month--month', data))
		end)

		it('Confirmed startMonth, startDay', function ()
			assert.are.equal('Oct 03', I18n.translate('date-range-month-day', data))
			assert.are.equal('Oct 03 - TBA', I18n.translate('date-range-month-day--unknown', data))
			assert.are.equal('Oct 03 - Nov TBA', I18n.translate('date-range-month-day--month-unknown_day', data))
			assert.are.equal('Oct 03 - Nov 04', I18n.translate('date-range-month-day--month-day', data))
		end)
	end)
end)
