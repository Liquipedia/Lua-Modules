--- Triple Comment to Enable our LLS Plugin
describe('Icon Maker', function()
	local Icon = require('Module:Icon')

	describe('font-awesome icon', function()
		local iconName = 'winner'
		local iconClass = 'fas fa-check'

		it('invalid input returns nil', function()
			assert.is_nil(Icon.makeIcon{iconName = 'nonExistingIcon'})
		end)

		it('icon builds', function()
			assert.are_equal('<i class="' .. iconClass .. '"></i>', Icon.makeIcon{iconName = iconName})
		end)

		it('can apply color', function()
			assert.are_equal('<i class="' .. iconClass .. ' forest-green-text"></i>',
				Icon.makeIcon{iconName = iconName, color = 'forest-green-text'})
		end)

		it('can hover text', function()
			assert.are_equal('<i class="' .. iconClass .. '" title="someTitle"></i>',
				Icon.makeIcon{iconName = iconName, hover = 'someTitle'})
		end)

		it('can set size pixels', function()
			assert.are_equal('<i class="' .. iconClass .. '" style="font-size:14px"></i>',
				Icon.makeIcon{iconName = iconName, size = 14})
			assert.are_equal('<i class="' .. iconClass .. '" style="font-size:14px"></i>',
				Icon.makeIcon{iconName = iconName, size = '14'})
		end)

		it('can set size string', function()
			assert.are_equal('<i class="' .. iconClass .. '" style="font-size:initial"></i>',
				Icon.makeIcon{iconName = iconName, size = 'initial'})
		end)

		it('can set hidden for screen readers', function()
			assert.are_equal('<i class="' .. iconClass .. '" aria-hidden="true"></i>',
				Icon.makeIcon{iconName = iconName, screenReaderHidden = true})
		end)

		it('no additional classes', function()
			assert.are_equal('<i class="' .. iconClass .. '"></i>',
				Icon.makeIcon{iconName = iconName, additionalClasses = {}})
		end)

		it('one additional class', function()
			assert.are_equal('<i class="' .. iconClass .. ' extra-class"></i>',
				Icon.makeIcon{iconName = iconName, additionalClasses = {'extra-class'}})
		end)

		it('multiple additional classes', function()
			assert.are_equal('<i class="' .. iconClass .. ' class-one class-two"></i>',
				Icon.makeIcon{iconName = iconName, additionalClasses = {'class-one', 'class-two'}})
		end)
	end)
end)
