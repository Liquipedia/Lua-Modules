--- Triple Comment to Enable our LLS Plugin
describe('prize pool', function()
	local PrizePool = require('Module:PrizePool')
	local InfoboxLeague = require('Module:Infobox/League/Custom')
	local Table = require('Module:Table')
	local Variables = require('Module:Variables')
	local tournamentData = require('test_assets.tournaments').dummy
	local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

	local LpdbPlacementStub

	before_each(function()
		-- Team templates are mocked for every test: TeamTemplate.getRawOrNil is
		-- memoized at module scope, so a team resolved without the mock caches a
		-- nil result that leaks into later tests that do expect the mock.
		TeamTemplateMock.setUp()
		stub(mw.ext.LiquipediaDB, "lpdb", {})
		stub(mw.ext.LiquipediaDB, "lpdb_tournament")
		LpdbPlacementStub = stub(mw.ext.LiquipediaDB, "lpdb_placement")
		InfoboxLeague.run(tournamentData)
	end)

	after_each(function ()
		TeamTemplateMock.tearDown()
		LpdbPlacementStub:revert()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
		mw.ext.LiquipediaDB.lpdb_tournament:revert()
	end)

	local prizePoolArgs = {
		type = {type = 'solo'},
		currencyroundprecision = 3,
		lpdb_prefix = 'abc',
		fillPlaceRange = true,
		localcurrency1 = 'EUR',
		localcurrency2 = 'sek',
		points1 = 'points',
		points1link = 'A Page',
		qualifies1 = 'A Tournament',
		qualifies1name = 'A Display',
		freetext = 'A title',
		import = false,
		[1] = {localprize = '1,000', [1] = {'Rathoz', flag='se'}},
		[2] = {qualified1 = true, [1] = {'Salt'}},
	}

	local clubSharePoolArgs = {
		type = {type = 'solo'},
		currencyroundprecision = 0,
		lpdb_prefix = 'cs',
		import = false,
		playershare = true,
		localcurrency = 'cny',
		autoexchange = true,
		[1] = {localprize = '160,000', playershare = '120,000', [1] = {'Serral', flag = 'fi'}},
		[2] = {localprize = '70,000', playershare = '50,000', [1] = {'Reynor', flag = 'it'}},
	}

	local clubShareUsdPoolArgs = {
		type = {type = 'team'},
		currencyroundprecision = 0,
		lpdb_prefix = 'csu',
		import = false,
		playershare = true,
		[1] = {usdprize = '400,000', playershare = '250,000', [1] = {'mouz'}},
		[2] = {usdprize = '130,000', playershare = '100,000', [1] = {'t1'}},
	}

	it('parameters are correctly parsed', function()
		local ppt = PrizePool(prizePoolArgs):create()

		assert.are_same(
			{
				{id = 'BASE_CURRENCY1', type = 'BASE_CURRENCY', index = 1, data = {roundPrecision = 3}},
				{
					id = 'LOCAL_CURRENCY1',
					type = 'LOCAL_CURRENCY',
					index = 1,
					data =
					{
						rate = 0.97097276906869001145,
						roundPrecision = 3,
						currency = 'EUR',
					}
				},
				{
					id = 'LOCAL_CURRENCY2',
					type = 'LOCAL_CURRENCY',
					index = 2,
					data =
					{
						rate = 0.97097276906869001145,
						roundPrecision = 3,
						currency = 'SEK',
					}
				},
				{id = 'POINTS1', type = 'POINTS', index = 1, data = {title = 'Points', link = 'A Page'}},
				{id = 'QUALIFIES1', type = 'QUALIFIES', index = 1, data = {title = 'A Display', link = 'A_Tournament'}},
				{id = 'FREETEXT1', type = 'FREETEXT', index = 1, data = {title = 'A title'}},
			},
			ppt.prizes
		)

		assert.are_same(
			{
				autoExchange = true,
				currencyRatePerOpponent = false,
				currencyRoundPrecision = 3,
				cutafter = 4,
				hideafter = math.huge,
				exchangeInfo = true,
				fillPlaceRange = true,
				lpdbPrefix = 'abc',
				playerShare = false,
				prizeSummary = true,
				resolveRedirect = false,
				showBaseCurrency = true,
				storeLpdb = true,
				syncPlayers = true,
			},
			ppt.options
		)
	end)

	it('enumerates currencies USD-first and distinct', function()
		local ppt = PrizePool(prizePoolArgs):create()
		assert.are_same({'USD', 'EUR', 'SEK'}, ppt:_getCurrencies())
	end)

	it('reads the playerShare config flag and raw player amounts', function()
		local ppt = PrizePool(clubSharePoolArgs):create()
		assert.is_true(ppt.options.playerShare)
		assert.are_equal(120000, ppt.placements[1].prizeRewards.playerShareInput)
		assert.are_equal(50000, ppt.placements[2].prizeRewards.playerShareInput)
	end)

	it('adds per-currency player/club share prizes in total→player→club order', function()
		local ppt = PrizePool(clubSharePoolArgs):create()
		local ids = {}
		for _, prize in ipairs(ppt.prizes) do
			table.insert(ids, prize.id)
		end
		assert.are_same(
			{'BASE_CURRENCY1', 'LOCAL_CURRENCY1', 'PLAYER_SHARE1', 'PLAYER_SHARE2', 'CLUB_SHARE1', 'CLUB_SHARE2'},
			ids
		)
		-- currency codes are carried on the share prizes (USD-first, then the local)
		local byId = {}
		for _, prize in ipairs(ppt.prizes) do byId[prize.id] = prize end
		assert.are_equal('USD', byId.PLAYER_SHARE1.data.currency)
		assert.are_equal('CNY', byId.PLAYER_SHARE2.data.currency)
		assert.are_equal('USD', byId.CLUB_SHARE1.data.currency)
		assert.are_equal('CNY', byId.CLUB_SHARE2.data.currency)
		-- enumeration is unaffected (deduped by code, USD-first)
		assert.are_same({'USD', 'CNY'}, ppt:_getCurrencies())
	end)

	it('derives club as total minus player, per currency', function()
		local ppt = PrizePool(clubSharePoolArgs):create()
		local placement = ppt.placements[1]
		local rewards = placement.opponents[1].prizeRewards
		-- Local (CNY, input currency): player is the raw input, club the remainder.
		-- The CNY total is at placement level (localprize is a slot-level input).
		local cnyTotal = placement.prizeRewards.LOCAL_CURRENCY1
		assert.are_equal(120000, rewards.PLAYER_SHARE2)
		assert.are_equal(cnyTotal - rewards.PLAYER_SHARE2, rewards.CLUB_SHARE2)
		-- Base (USD): player exchanged from the local input; club still total − player.
		assert.are_equal(rewards.BASE_CURRENCY1 - rewards.PLAYER_SHARE1, rewards.CLUB_SHARE1)
		assert.is_true(rewards.PLAYER_SHARE1 > 0)
	end)

	it('tags player/club money cells with their currency toggle index', function()
		local output = tostring(PrizePool(Table.merge(clubSharePoolArgs, {storelpdb = false})):create():build())
		-- USD columns (toggle area 1) and CNY columns (toggle area 2) both present.
		assert.is_truthy(output:find('data-toggle-area-content="1"', 1, true))
		assert.is_truthy(output:find('data-toggle-area-content="2"', 1, true))
		assert.is_truthy(output:find('Player Prize', 1, true))
		assert.is_truthy(output:find('Club Reward', 1, true))
		-- Positively assert the pill is present.
		assert.is_truthy(output:find('switch-pill', 1, true))
		-- Assert column order (Player Prize appears before Club Reward).
		assert.is_true(output:find('Player Prize', 1, true) < output:find('Club Reward', 1, true))
	end)

	it('renders club-share columns without a currency toggle for a single currency', function()
		local output = tostring(PrizePool(Table.merge(clubShareUsdPoolArgs, {storelpdb = false})):create():build())
		assert.is_truthy(output:find('Player Prize', 1, true))
		assert.is_truthy(output:find('Club Reward', 1, true))
		assert.is_nil(output:find('switch-pill', 1, true))
		-- Assert no toggle attribute is emitted.
		assert.is_nil(output:find('data-toggle-area-content', 1, true))
		-- Assert column order too.
		assert.is_true(output:find('Player Prize', 1, true) < output:find('Club Reward', 1, true))
	end)

	describe('prize pool is correct', function()
		it('display #snapshot', function()
			GoldenTest('prize_pool', tostring(PrizePool(prizePoolArgs):create():build()))
			local clubShareNoStore = Table.merge(clubSharePoolArgs, {storelpdb = false})
			GoldenTest('prize_pool_club_share', tostring(PrizePool(clubShareNoStore):create():build()))
		end)

		it('lpdb storage', function()
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).was.called_with('ranking_abc1_Rathoz', {
				date = '2022-10-15',
				extradata = '{"prizepoints":"","prizepoints2":""}',
				game = 'commons',
				icon = 'test.png',
				icondark = 'test dark.png',
				individualprizemoney = 970.97276906869001323,
				lastvsdata = '[]',
				liquipediatier = '1',
				liquipediatiertype = 'Qualifier',
				opponentname = 'Rathoz',
				opponentplayers = '{"p1":"Rathoz","p1dn":"Rathoz","p1flag":"Sweden"}',
				opponenttype = 'solo',
				parent = 'FakePage',
				participant = 'Rathoz', -- Legacy
				participantflag = 'Sweden', -- Legacy
				participantlink = 'Rathoz', -- Legacy
				placement = 1,
				players = '{"p1":"Rathoz","p1dn":"Rathoz","p1flag":"Sweden"}', -- Legacy
				prizemoney = 970.97276906869001323,
				prizepoolindex = 1,
				series = 'Test Series',
				shortname = 'Test Tourney',
				startdate = '2022-10-13',
				tournament = 'Test Tournament',
				type = 'Offline',
				qualified = 0,
			})
			assert.stub(LpdbPlacementStub).was.called_with('ranking_abc1_Salt', {
				date = '2022-10-15',
				extradata = '{"prizepoints":"","prizepoints2":""}',
				game = 'commons',
				icon = 'test.png',
				icondark = 'test dark.png',
				individualprizemoney = 0,
				lastvsdata = '[]',
				liquipediatier = '1',
				liquipediatiertype = 'Qualifier',
				opponentname = 'Salt',
				opponentplayers = '{"p1":"Salt","p1dn":"Salt"}',
				opponenttype = 'solo',
				parent = 'FakePage',
				participant = 'Salt', -- Legacy
				participantflag = nil, -- Legacy
				participantlink = 'Salt', -- Legacy
				placement = 2,
				players = '{"p1":"Salt","p1dn":"Salt"}', -- Legacy
				prizemoney = 0,
				prizepoolindex = 1,
				series = 'Test Series',
				shortname = 'Test Tourney',
				startdate = '2022-10-13',
				tournament = 'Test Tournament',
				type = 'Offline',
				qualified = 1,
			})
		end)
	end)

	it('tags money columns with their currency toggle index', function()
		local output = tostring(PrizePool(prizePoolArgs):create():build())
		assert.is_truthy(output:find('data-toggle-area-content="1"', 1, true)) -- USD
		assert.is_truthy(output:find('data-toggle-area-content="2"', 1, true)) -- EUR
		assert.is_truthy(output:find('data-toggle-area-content="3"', 1, true)) -- SEK
	end)

	it('wraps a multi-currency table in a currency toggle', function()
		local output = tostring(PrizePool(prizePoolArgs):create():build())
		assert.is_truthy(output:find('switch-pill', 1, true))
		assert.is_truthy(output:find('prizepool-currency-switch', 1, true))
		assert.is_truthy(output:find('data-toggle-area="2"', 1, true)) -- default = first local (EUR)
	end)

	it('renders no currency toggle for a single currency', function()
		local singleArgs = Table.merge({}, prizePoolArgs)
		singleArgs.localcurrency1 = nil
		singleArgs.localcurrency2 = nil
		local output = tostring(PrizePool(singleArgs):create():build())
		assert.is_nil(output:find('switch-pill', 1, true))
	end)

	it('stores the USD player share in placement extradata', function()
		local Json = require('Module:Json')
		PrizePool(clubShareUsdPoolArgs):create():build()

		local playerShares = {}
		for _, call in ipairs(LpdbPlacementStub.calls) do
			local extradata = call.vals[2] and call.vals[2].extradata
			local parsed = extradata and Json.parseIfString(extradata)
			if parsed and parsed.playershare then
				table.insert(playerShares, parsed.playershare)
			end
		end
		assert.are_same({250000, 100000}, playerShares)
	end)

	describe('enabling/disabling lpdb storage', function()
		it('normal behavior', function()
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).called(2)
		end)

		it('disabled', function()
			PrizePool(Table.merge(prizePoolArgs, {storelpdb = false})):create():build()
			assert.stub(LpdbPlacementStub).called(0)
		end)

		it('wiki-var enabled', function()
			Variables.varDefine('disable_LPDB_storage', 'false')
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).called(2)
		end)

		it('wiki-var enabled with override', function()
			Variables.varDefine('disable_LPDB_storage', 'false')
			PrizePool(Table.merge(prizePoolArgs, {storelpdb = false})):create():build()
			assert.stub(LpdbPlacementStub).called(0)
		end)


		it('wiki-var disable with override', function()
			Variables.varDefine('disable_LPDB_storage', 'true')
			PrizePool(Table.merge(prizePoolArgs, {storelpdb = true})):create():build()
			assert.stub(LpdbPlacementStub).called(2)
		end)

		it('wiki-var disable without override', function()
			Variables.varDefine('disable_LPDB_storage', 'true')
			PrizePool(prizePoolArgs):create():build()
			assert.stub(LpdbPlacementStub).called(0)
		end)
	end)
end)
