--- Triple Comment to Enable our LLS Plugin
describe('logic', function()
	local TextSanitizer = require('Module:TextSanitizer')

	describe('strip HTML', function()
		it('check', function()
			assert.are_equal('Bar', TextSanitizer.stripHTML('<b class="foo">Bar</b>'))
			assert.are_equal('A -B', TextSanitizer.stripHTML('A&zwj;&nbsp;—B'))
			assert.are_equal('AB', TextSanitizer.stripHTML('A&shy;B'))
		end)
	end)
end)
