---@diagnostic disable: param-type-mismatch
--- Triple Comment to Enable our LLS Plugin
describe('Date', function()
	local Variables = require('Module:Variables')
	local DateExt = require('Module:Date/Ext')

	local FormatDateSpy

	before_each(function()
		-- Because of the complex nature of `formatDate`, a lot of the tests are just "check it has been called"
		FormatDateSpy = spy.on(mw.language, 'formatDate')
	end)

	after_each(function()
		FormatDateSpy:revert()
	end)

	describe('read timestamp', function()
		it('verify', function()
			DateExt.readTimestamp('2021-10-17 17:40 <abbr data-tz="-4:00">EDT</abbr>')
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'U', '20211017 17:40 -4:00')

			DateExt.readTimestamp('2021-10-17 - 17:40 <abbr data-tz="-4:00">EDT</abbr>')
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'U', '20211017 17:40 -4:00')

			DateExt.readTimestamp('2021-10-17 21:40')
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'U', '20211017 21:40')

			DateExt.readTimestamp('2024-11-24T15:38:01')
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'U', '2024112415:38:01')

			DateExt.readTimestamp('2024-11-24T15:38:01.999Z')
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'U', '2024112415:38:01.999Z')
		end)
	end)

	describe('format', function()
		it('verify', function()
			DateExt.formatTimestamp('c', 1634506800)
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'c', '@' .. 1634506800)
		end)
	end)

	describe('toYmdInUtc', function()
		it('verify', function()
			DateExt.toYmdInUtc('November 08, 2021 - 13:00 <abbr data-tz="+2:00">CET</abbr>')
			assert.stub(FormatDateSpy).was.called_with(mw.language, 'Y-m-d', '@')
		end)
	end)

	describe('getContextualDateOrNow', function()
		it('verify', function()
			assert.are_equal(os.date('%F'), DateExt.getContextualDateOrNow())
			assert.are_equal(nil, DateExt.getContextualDate())

			Variables.varDefine('tournament_startdate', '2021-12-24')
			assert.are_equal('2021-12-24', DateExt.getContextualDateOrNow())
			assert.are_equal('2021-12-24', DateExt.getContextualDate())

			Variables.varDefine('tournament_enddate', '2021-12-28')
			assert.are_equal('2021-12-28', DateExt.getContextualDateOrNow())
			assert.are_equal('2021-12-28', DateExt.getContextualDate())

			Variables.varDefine('tournament_startdate')
			Variables.varDefine('tournament_enddate')
		end)
	end)

	describe('parse iso date', function()
		it('verify', function()
			assert.are_same({year = 2023, month = 7, day = 24}, DateExt.parseIsoDate('2023-07-24'))
			assert.are_same({year = 2023, month = 7, day = 24},
				DateExt.parseIsoDate('2023-07-24asdkosdkmoasjoikmakmslkm'))
			assert.are_same({year = 2023, month = 7, day = 1}, DateExt.parseIsoDate('2023-07'))
			assert.are_same({year = 2023, month = 7, day = 1}, DateExt.parseIsoDate('2023-07sdfsdfdfs'))
			assert.are_same({year = 2023, month = 1, day = 1}, DateExt.parseIsoDate('2023'))
			assert.is_nil(DateExt.parseIsoDate())
		end)
	end)

	describe('is default timestamp', function()
		it('verify', function()
			assert.is_false(DateExt.isDefaultTimestamp(''))
			assert.is_false(DateExt.isDefaultTimestamp('2023-07-24'))
			assert.is_false(DateExt.isDefaultTimestamp(0))
			assert.is_true(DateExt.isDefaultTimestamp(DateExt.defaultTimestamp))
			assert.is_true(DateExt.isDefaultTimestamp(DateExt.defaultDate))
			assert.is_true(DateExt.isDefaultTimestamp(DateExt.defaultDateTime))
			assert.is_true(DateExt.isDefaultTimestamp(DateExt.defaultDateTimeExtended))
			assert.is_true(DateExt.isDefaultTimestamp(DateExt.defaultDate))
		end)
	end)

	describe('nill if default timestamp', function()
		it('verify', function()
			assert.are_same('2023-07-24', DateExt.nilIfDefaultTimestamp('2023-07-24'))
			assert.is_nil(DateExt.nilIfDefaultTimestamp(DateExt.defaultTimestamp))
			assert.is_nil(DateExt.nilIfDefaultTimestamp(DateExt.defaultDateTime))
			assert.is_nil(DateExt.nilIfDefaultTimestamp(DateExt.defaultDateTimeExtended))
			assert.is_nil(DateExt.nilIfDefaultTimestamp(DateExt.defaultDate))
		end)
	end)
end)
