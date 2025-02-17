--- Triple Comment to Enable our LLS Plugin
describe('LPDB Object-Relational Mapping', function()
	local Lpdb = require('Module:Lpdb')

	describe('setting data', function()
		it('assign value on init', function()
			local match2 = Lpdb.Match2:new({bestof = 10})
			assert.are_same({bestof = 10}, rawget(match2, 'fields'))
		end)

		it('__newindex', function()
			local match2 = Lpdb.Match2:new()
			match2.bestof = 7
			assert.are_same({bestof = 7}, rawget(match2, 'fields'))
		end)

		it('set()', function()
			local match2 = Lpdb.Match2:new():set('bestof', 5)
			assert.are_same({bestof = 5}, rawget(match2, 'fields'))
		end)

		it('setMany()', function()
			local match2 = Lpdb.Match2:new():setMany{bestof = 3, game = 'r6s'}
			assert.are_same({bestof = 3, game = 'r6s'}, rawget(match2, 'fields'))
		end)

		it('strip html tags', function()
			local match2 = Lpdb.Match2:new():set('match2bracketdata', {header = '<abbr title="Best of 5">Bo5</abbr>'})
			assert.are_same({match2bracketdata = {header = 'Bo5'}}, rawget(match2, 'fields'))
		end)
	end)

	describe('saving data', function()
		it('saving', function()
			local stub = stub(mw.ext.LiquipediaDB, 'lpdb_match2')
			Lpdb.Match2:new({match2id = 'Foo', match2bracketid = 'Bar', bestof = 3, game = 'r6s'}):save()
			assert.stub(stub).called_with('Foo', {
				bestof = 3,
				date = 0,
				dateexact = 0,
				extradata = {},
				finished = 0,
				game = 'r6s',
				icon = '',
				icondark = '',
				links = {},
				liquipediatier = '',
				liquipediatiertype = '',
				match2bracketdata = {},
				match2bracketid = 'Bar',
				match2games = {},
				match2id = 'Foo',
				match2opponents = {},
				mode = '',
				parent = '',
				patch = '',
				publishertier = '',
				section = '',
				series = '',
				shortname = '',
				stream = {},
				tickername = '',
				tournament = '',
				type = '',
				vod = '',
				winner = '',
			})
			stub:revert()
		end)
	end)
end)
