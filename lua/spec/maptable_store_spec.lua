--- Triple Comment to Enable our LLS Plugin
-- Storage layer of Module:Features/MapTable: what storeMaps writes to LPDB

describe('MapTable Storage', function()
	local MapTableStore

	setup(function()
		SetActiveWiki('trackmania')
		MapTableStore = require('Module:Features/MapTable/Api/Store')
	end)

	teardown(function()
		SetActiveWiki()
	end)

	it('stores one datapoint per map, named after the map', function()
		local stubLpdb = stub(mw.ext.LiquipediaDB, 'lpdb_datapoint')

		MapTableStore.storeMaps(
			{{map = 'Stadium'}, {map = 'Desert'}},
			{{}, {}},
			{{}, {}}
		)

		assert.stub(stubLpdb).was.called(2)
		assert.stub(stubLpdb).was.called_with('map_Stadium', {name = 'Stadium', type = 'map', extradata = '[]'})
		assert.stub(stubLpdb).was.called_with('map_Desert', {name = 'Desert', type = 'map', extradata = '[]'})

		stubLpdb:revert()
	end)

	it('stores the mappers and the links in the extradata', function()
		local stubLpdb = stub(mw.ext.LiquipediaDB, 'lpdb_datapoint')

		MapTableStore.storeMaps(
			{{map = 'Stadium'}},
			{{
				{index = 1, displayName = 'Player One', pageName = 'Player One', flag = 'Sweden'},
				{index = 2, displayName = 'Player Two'},
			}},
			{{twitch = 'https://www.twitch.tv/channel'}}
		)

		assert.stub(stubLpdb).was.called_with('map_Stadium', {
			name = 'Stadium',
			type = 'map',
			extradata = '{"author1":"Player_One","author1dn":"Player One","author1flag":"Sweden",'
				.. '"author2":"","author2dn":"Player Two","author2flag":"",'
				.. '"links":{"twitch":"https://www.twitch.tv/channel"}}',
		})

		stubLpdb:revert()
	end)

	it('stores nothing for a row without a map', function()
		local stubLpdb = stub(mw.ext.LiquipediaDB, 'lpdb_datapoint')

		MapTableStore.storeMaps({{map = ''}}, {{}}, {{}})

		assert.stub(stubLpdb).was.called(0)

		stubLpdb:revert()
	end)

	it('stores nothing while storage is disabled', function()
		local stubLpdb = stub(mw.ext.LiquipediaDB, 'lpdb_datapoint')
		mw.ext.VariablesLua.vardefine('disable_LPDB_storage', '1')

		MapTableStore.storeMaps({{map = 'Stadium'}}, {{}}, {{}})

		assert.stub(stubLpdb).was.called(0)

		stubLpdb:revert()
	end)
end)
