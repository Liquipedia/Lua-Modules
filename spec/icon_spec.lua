--- Triple Comment to Enable our LLS Plugin
describe('Icon Maker', function()
	local Icon = require('Module:Icon')

	describe('font-awesome icon', function()
		it('invalid input returns nil', function()
			assert.is_nil(Icon.makeIcon{})
			assert.is_nil(Icon.makeIcon{icon = 'foo bar'})
		end)

		it('icon builds', function()
			assert.are_equal('<i class="fas fa-check"></i>', Icon.makeIcon{iconName = 'check'})
		end)

		it('can apply color', function()
			assert.are_equal('<i class="fas fa-check forest-green-text"></i>', Icon.makeIcon{iconName = 'check', color = 'forest-green-text'})
		end)

		it('can hover text', function()
			assert.are_equal('<i class="fas fa-check" title="someTitle"></i>', Icon.makeIcon{iconName = 'check', hover = 'someTitle'})
		end)

		it('can set size pixels', function()
			assert.are_equal('<i class="fas fa-check" style="font-size:14px"></i>', Icon.makeIcon{iconName = 'check', size = 14})
			assert.are_equal('<i class="fas fa-check" style="font-size:14px"></i>', Icon.makeIcon{iconName = 'check', size = '14'})
		end)

		it('can set size string', function()
			assert.are_equal('<i class="fas fa-check" style="font-size:initial"></i>', Icon.makeIcon{iconName = 'check', size = 'initial'})
		end)

		it('can set hidden for screen readers', function()
			assert.are_equal('<i class="fas fa-check" aria-hidden="true"></i>', Icon.makeIcon{iconName = 'check', screenReaderHidden = true})
		end)
	end)
end)
