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
end)
