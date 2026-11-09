--- Triple Comment to Enable our LLS Plugin
describe('Widget/Documentation/Para', function()
	local Para = require('Module:Widget/Documentation/Para')

	it('renders like Template:Para', function()
		assert.are_equal('<code class="nowrap">&#124;store&#61;false</code>', tostring(Para{name = 'store', value = false}))
		assert.are_equal('<code class="nowrap">&#124;title&#61;</code>', tostring(Para{name = 'title'}))
	end)

	it('renders an unnamed parameter by its value, as written', function()
		assert.are_equal(
			'<code class="nowrap">&#124;&#123;&#123;TeamOpponent&#124;...&#125;&#125;</code>',
			tostring(Para{value = '{{TeamOpponent|...}}'})
		)
	end)
end)
