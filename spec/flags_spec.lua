--- Triple Comment to Enable our LLS Plugin
describe('flags', function()
	local Flags = require('Module:Flags')
	local Template = require('Module:Template')

	describe('icon', function()
		it('check', function()
			local nlOutput = '<span class=\"flag\">[[File:nl_hd.png|36x24px|Netherlands|link=]]</span>'
			local nlOutputLink = '<span class=\"flag\">[[File:nl_hd.png|36x24px|Netherlands|link=Category:Netherlands]]</span>'

			assert.are_equal(nlOutput, Flags.Icon('nl'))
			assert.are_equal(nlOutput, Flags.Icon('nld'))
			assert.are_equal(nlOutput, Flags.Icon('holland'))
			assert.are_equal(nlOutput, Flags.Icon({}, 'nl'))
			assert.are_equal(nlOutput, Flags.Icon({}, 'nld'))
			assert.are_equal(nlOutput, Flags.Icon({}, 'holland'))
			assert.are_equal(nlOutputLink, Flags.Icon({shouldLink = true}, 'nl'))
			assert.are_equal(nlOutputLink, Flags.Icon({shouldLink = true}, 'nld'))
			assert.are_equal(nlOutputLink, Flags.Icon({shouldLink = true}, 'holland'))
			assert.are_equal(nlOutput, Flags.Icon({shouldLink = false}, 'nl'))
			assert.are_equal(nlOutput, Flags.Icon({shouldLink = false}, 'nld'))
			assert.are_equal(nlOutput, Flags.Icon({shouldLink = false}, 'holland'))
			assert.are_equal(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'nl'})
			assert.are_equal(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'nld'})
			assert.are_equal(nlOutputLink, Flags.Icon{shouldLink = true, flag = 'holland'})
			assert.are_equal(nlOutput, Flags.Icon{shouldLink = false, flag = 'nl'})
			assert.are_equal(nlOutput, Flags.Icon{shouldLink = false, flag = 'nld'})
			assert.are_equal(nlOutput, Flags.Icon{shouldLink = false, flag = 'holland'})

			assert.are_equal('<span class=\"flag\">[[File:Space filler flag.png|36x24px|link=]]</span>',
				Flags.Icon{flag = 'tbd'})

			local TemplateMock = stub(Template, "safeExpand")

			Flags.Icon{shouldLink = true, flag = 'dummy'}
			assert.stub(TemplateMock).was.called_with(nil, 'Flag/dummy')

			Flags.Icon{shouldLink = false, flag = 'dummy'}
			assert.stub(TemplateMock).was.called_with(nil, 'FlagNoLink/dummy')
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
				Flags.languageIcon('en'))
			assert.are_equal('<span class=\"flag\">[[File:nl_hd.png|36x24px|Netherlands|link=]]</span>',
				Flags.languageIcon('nl'))
		end)
	end)

	describe('country name', function()
		it('check', function()
			local nlOutput = 'Netherlands'
			assert.are_equal(nlOutput, Flags.CountryName('nl'))
			assert.are_equal(nlOutput, Flags.CountryName('Netherlands'))
			assert.are_equal(nlOutput, Flags.CountryName('netherlands'))
			assert.are_equal(nlOutput, Flags.CountryName('holland'))
		end)
	end)

	describe('country code', function()
		it('check', function()
			local nlOutput = 'nl'
			assert.are_equal(nlOutput, Flags.CountryCode('nl'))
			assert.are_equal(nlOutput, Flags.CountryCode('Netherlands'))
			assert.are_equal(nlOutput, Flags.CountryCode('netherlands'))
			assert.are_equal(nlOutput, Flags.CountryCode('holland'))
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
