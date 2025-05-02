--- Triple Comment to Enable our LLS Plugin
describe('flags', function()
	local Flags = require('Module:Flags')

	describe('icon', function()
		it('check', function()
			local nlOutput = '<span class=\"flag\">[[File:nl_hd.png|36x24px|Netherlands|link=]]</span>'
			local nlOutputLink = '<span class=\"flag\">[[File:nl_hd.png|36x24px|Netherlands|link=Category:Netherlands]]</span>'

			assert.are_equal(nlOutput, Flags.Icon{flag = 'nl'})
			assert.are_equal(nlOutput, Flags.Icon{flag = 'nld'})
			assert.are_equal(nlOutput, Flags.Icon{flag = 'holland'})
			assert.are_equal(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'nl'})
			assert.are_equal(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'nld'})
			assert.are_equal(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'holland'})
			assert.are_equal(nlOutput, Flags.Icon{shouldLink = false, flag = 'nl'})
			assert.are_equal(nlOutput, Flags.Icon{shouldLink = false, flag = 'nld'})
			assert.are_equal(nlOutput, Flags.Icon{shouldLink = false, flag = 'holland'})

			assert.are_equal('<span class=\"flag\">[[File:Space filler flag.png|36x24px||link=]]</span>',
				Flags.Icon{flag = 'tbd'})

			assert.are_equal('Unknown flag: dummy',
				Flags.Icon{shouldLink = true, flag = 'dummy'})
		end)
	end)

	describe('localisation', function()
		it('check', function()
			local nlOutput = 'Dutch'
			assert.are_equal(nlOutput, Flags.getLocalisation('nl'))
			assert.are_equal(nlOutput, Flags.getLocalisation('Netherlands'))
			assert.are_equal(nlOutput, Flags.getLocalisation('netherlands'))
			assert.are_equal(nlOutput, Flags.getLocalisation('holland'))
		end)
	end)

	describe('language icon', function()
		it('check', function()
			assert.are_equal('<span class=\"flag\">[[File:UsGb hd.png|36x24px|English Speaking|link=]]</span>',
				Flags.languageIcon{language = 'en'})
			assert.are_equal('<span class=\"flag\">[[File:nl_hd.png|36x24px|Netherlands|link=]]</span>',
				Flags.languageIcon{language = 'nl'})
		end)
	end)

	describe('country name', function()
		it('check', function()
			local nlOutput = 'Netherlands'
			assert.are_equal(nlOutput, Flags.CountryName{flag = 'nl'})
			assert.are_equal(nlOutput, Flags.CountryName{flag = 'Netherlands'})
			assert.are_equal(nlOutput, Flags.CountryName{flag = 'netherlands'})
			assert.are_equal(nlOutput, Flags.CountryName{flag = 'holland'})
		end)
	end)

	describe('country code', function()
		it('check', function()
			local nlOutput = 'nl'
			assert.are_equal(nlOutput, Flags.CountryCode{flag = 'nl'})
			assert.are_equal(nlOutput, Flags.CountryCode{flag = 'Netherlands'})
			assert.are_equal(nlOutput, Flags.CountryCode{flag = 'netherlands'})
			assert.are_equal(nlOutput, Flags.CountryCode{flag = 'holland'})
		end)
	end)

	describe('is valid flag', function()
		it('check', function()
			assert.is_true(Flags.isValidFlagInput('de'))
			assert.is_true(Flags.isValidFlagInput('germany'))
			assert.is_false(Flags.isValidFlagInput('aaaaaaa'))
		end)
	end)
end)
