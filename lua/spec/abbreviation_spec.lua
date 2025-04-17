--- Triple Comment to Enable our LLS Plugin
describe('abbreviation', function()
	local Abbreviation = require('Module:Abbreviation')

	describe('make abbreviation', function()
		it('Empty input returns nil', function()
			assert.is_nil(Abbreviation.make())
			assert.is_nil(Abbreviation.make{text = ''})
		end)
		it('Only one input returns nil', function()
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_nil(Abbreviation.make{text = 'Abc'})
			assert.is_nil(Abbreviation.make{text = '', title = 'Def'})
		end)
		it('Abbreviation works', function()
			assert.are_same('<abbr title="Cookie">Cake</abbr>', Abbreviation.make{text = 'Cake', title = 'Cookie'})
		end)
	end)
end)
