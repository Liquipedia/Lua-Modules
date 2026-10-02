--- Triple Comment to Enable our LLS Plugin
-- Pure Lib layer of Module:Features/MapTable: rows, mappers and links, no mocks

describe('MapTable Lib', function()
	local MapTableParse

	setup(function()
		SetActiveWiki('trackmania')
		MapTableParse = require('Module:Features/MapTable/Lib/Parse')
	end)

	teardown(function()
		SetActiveWiki()
	end)

	describe('readRows', function()
		it('reads the indexed args into rows', function()
			local rows = MapTableParse.readRows{
				[1] = '{"map":"Stadium","mapper1":"Player One"}',
				[2] = '{"map":"Desert"}',
			}

			assert.are_equal(2, #rows)
			assert.are_equal('Stadium', rows[1].map)
			assert.are_equal('Player One', rows[1].mapper1)
			assert.are_equal('Desert', rows[2].map)
		end)

		it('reads no rows from empty args', function()
			assert.are_equal(0, #MapTableParse.readRows{})
		end)
	end)

	describe('readMappers', function()
		it('reads the mapper, author and a prefixes in order', function()
			local mappers = MapTableParse.readMappers{
				map = 'Stadium',
				mapper1 = 'Player One',
				author2 = 'Player Two',
				a3 = 'Player Three',
			}

			assert.are_equal(3, #mappers)
			assert.are_equal(1, mappers[1].index)
			assert.are_equal(2, mappers[2].index)
			assert.are_equal(3, mappers[3].index)
			assert.are_equal('Player One', mappers[1].displayName)
			assert.are_equal('Player Two', mappers[2].displayName)
			assert.are_equal('Player Three', mappers[3].displayName)
		end)

		it('resolves the flag of the row', function()
			local mappers = MapTableParse.readMappers{mapper1 = 'Player One', mapper1flag = 'se'}

			assert.are_equal('Sweden', mappers[1].flag)
		end)

		it('leaves the page name unset, because resolving it needs a lookup', function()
			local mappers = MapTableParse.readMappers{mapper1 = 'Player One'}

			assert.is_nil(mappers[1].pageName)
		end)

		it('reads no mappers from a row without one', function()
			assert.are_equal(0, #MapTableParse.readMappers{map = 'Stadium'})
		end)
	end)

	describe('makeFullLinks', function()
		it('builds full links for the row', function()
			local links = MapTableParse.makeFullLinks{twitch = 'channel'}

			assert.are_equal('https://www.twitch.tv/channel', links.twitch)
		end)

		it('drops links the row left empty', function()
			local links = MapTableParse.makeFullLinks{twitch = 'channel', empty = ''}

			assert.is_nil(links.empty)
		end)

		it('does not turn non-link args into links', function()
			local links = MapTableParse.makeFullLinks{map = 'Stadium'}

			assert.is_nil(links.map)
		end)
	end)
end)
