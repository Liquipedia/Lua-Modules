--- Triple Comment to Enable our LLS Plugin
describe('reference cleaner', function()
	local ReferenceCleaner = require('Module:ReferenceCleaner')

	describe('date cleaning', function()
		it('check', function()
			assert.are_equal('2021-07-05', ReferenceCleaner.clean{input = '2021-07-05'})
			assert.are_equal('2011-05-01', ReferenceCleaner.clean{input = '2011-05-??'})
			assert.are_equal('2011-01-05', ReferenceCleaner.clean{input = '2011-??-05'})
		end)
	end)
end)
