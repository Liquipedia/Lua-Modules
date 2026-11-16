--- Triple Comment to Enable our LLS Plugin
describe('Standings round selector', function()
	local RoundSelector = require('Module:Widget/Standings/RoundSelector')

	it('renders nothing for a single round', function()
		assert.are_equal('', tostring(RoundSelector{rounds = 1}))
	end)

	it('numbers the rounds and calls the last one current while the standings are ongoing', function()
		local html = tostring(RoundSelector{rounds = 2, hasEnded = false})
		assert.is_truthy(html:find('>Round 1<', 1, true))
		assert.is_truthy(html:find('>Current<', 1, true))
		assert.is_falsy(html:find('>Round 2<', 1, true))
	end)

	it('uses the given round titles', function()
		local html = tostring(RoundSelector{rounds = 2, hasEnded = true, titles = {'Week 1', 'Week 2'}})
		assert.is_truthy(html:find('>Week 1<', 1, true))
		assert.is_truthy(html:find('>Week 2<', 1, true))
		assert.is_falsy(html:find('Round', 1, true))
	end)
end)
