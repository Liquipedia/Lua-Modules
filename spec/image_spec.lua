--- Triple Comment to Enable our LLS Plugin
describe('image', function()
	local Image = require('Module:Image')

	describe('display', function()
		it('allmode', function()
			assert.are_same('[[File:test]]', Image.display('test'))
		end)

		it('light and darkmode', function()
			assert.are_same('[[File:test|class=show-when-light-mode]][[File:test2|class=show-when-dark-mode]]',
				Image.display('test', 'test2'))
		end)

		it('options', function()
			assert.are_same('[[File:test|10px|link=test3|class=show-when-light-mode|capt]]'
				.. '[[File:test2|10px|link=test3|class=show-when-dark-mode|capt]]',
				Image.display('test', 'test2', {
					link = 'test3',
					size = 10,
					caption = 'capt'
				}))
		end)
	end)
end)
