--- Triple Comment to Enable our LLS Plugin
describe('region', function()
	local Flags = require('Module:Flags')
	local Region = require('Module:Region')

	describe('name', function()
		it('check', function()
			assert.are_equal('', Region.name{region = ''})
			assert.are_equal('', Region.name{})
			assert.are_equal('', Region.name())
			assert.are_equal('Europe', Region.name{region = 'Europe'})
			assert.are_equal('South America', Region.name{region = 'sam'})
			assert.are_equal('Europe', Region.name{region = 'eu'})
		end)
	end)

	describe('display', function()
		it('check', function()
			local euFlag = Flags.Icon{flag = 'eu', shouldLink = true}
			assert.are_equal(euFlag .. '&nbsp;Europe', Region.display{region = 'Europe', linkToCategory‎ = true})
			assert.are_equal('<span class="flag">[[File:unasur hd.png|36x24px|South America' ..
				'|link=Category:South America]]</span>&nbsp;South America', Region.display{region = 'sam'})
			assert.are_equal(euFlag .. '&nbsp;Europe', Region.display{region = 'eu'})
		end)
	end)

	describe('run', function()
		it('check', function()
			local euFlag = Flags.Icon{flag = 'eu'}
			assert.are_same({display = euFlag .. '&nbsp;Europe', region = 'Europe'}, Region.run{region = 'Europe'})
			assert.are_same(
				{
					display = '<span class="flag">[[File:unasur hd.png|36x24px|South America' ..
						'|link=Category:South America]]</span>&nbsp;South America',
					region = 'South America'
				},
				Region.run{region = 'South America', linkToCategory‎ = true}
			)
			assert.are_same({}, Region.run{})
			assert.are_same({}, Region.run{region = ''})
			assert.are_same({}, Region.run{country = ''})
		end)
	end)
end)
