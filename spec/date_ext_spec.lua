--- Triple Comment to Enable our LLS Plugin
describe('Variables', function()
	local Variables = require('Module:Variables')

	local DateExt = require('Module:Date/Ext')

	local LanguageMock

	before_each(function()
		-- Because of the complex nature of `formatDate`, a lot of the tests are just "check it has been called"
		LanguageMock = mock(mw.language, true)
	end)

	describe('read timestamp', function()
		it('verify', function()
			DateExt.readTimestamp('2021-10-17 17:40 <abbr data-tz="-4:00">EDT</abbr>')
			assert.stub(LanguageMock.formatDate).was.called_with(LanguageMock, 'U', '20211017 17:40 -4:00')

			DateExt.readTimestamp('2021-10-17 21:40')
			assert.stub(LanguageMock.formatDate).was.called_with(LanguageMock, 'U', '20211017 21:40')
		end)
	end)

	describe('format', function()
		it('verify', function()
			DateExt.formatTimestamp('c', 1634506800)
			assert.stub(LanguageMock.formatDate).was.called_with(LanguageMock, 'c', '@' .. 1634506800)
		end)
	end)

	describe('toYmdInUtc', function()
		it('verify', function()
			DateExt.toYmdInUtc('November 08, 2021 - 13:00 <abbr data-tz="+2:00">CET</abbr>')
			assert.stub(LanguageMock.formatDate).was.called_with(LanguageMock, 'Y-m-d', '@')
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
end)
