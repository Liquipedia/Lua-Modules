--- Triple Comment to Enable our LLS Plugin
insulate('Trackmania match2', function()
	local LpdbStub
	setup(function()
		SetActiveWiki('trackmania')
		LpdbStub = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {} end)
	end)
	teardown(function()
		if LpdbStub then
			LpdbStub:revert()
		end
		SetActiveWiki()
	end)

	describe('match input', function()
		local CustomMatchGroupInput = require('Module:MatchGroup/Input/Custom')

		it('parses 3-4 solo opponents as FFA', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1', score = 123},
				opponent2 = {type = 'solo', name = 'Player2', score = 122},
				opponent3 = {type = 'solo', name = 'Player3', score = 121},
				opponent4 = {type = 'solo', name = 'Player4', score = 97},
			}

			assert.are_same({1, 2, 3, 4}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
				processed.opponents[4].placement,
			})
		end)

		it('parses 3-4 opponents of any type as FFA', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'duo', p1 = 'Player1', p2 = 'Player2', score = 3},
				opponent2 = {type = 'duo', p1 = 'Player3', p2 = 'Player4', score = 2},
				opponent3 = {type = 'duo', p1 = 'Player5', p2 = 'Player6', score = 1},
			}

			assert.are_same({1, 2, 3}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
			})
		end)

		it('keeps 5+ opponents as FFA', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1', score = 5},
				opponent2 = {type = 'solo', name = 'Player2', score = 4},
				opponent3 = {type = 'solo', name = 'Player3', score = 3},
				opponent4 = {type = 'solo', name = 'Player4', score = 2},
				opponent5 = {type = 'solo', name = 'Player5', score = 1},
			}

			assert.are_same({1, 2, 3, 4, 5}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
				processed.opponents[4].placement,
				processed.opponents[5].placement,
			})
		end)

		it('keeps 2-player matches on standard match2', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1', score = 2},
				opponent2 = {type = 'solo', name = 'Player2', score = 1},
				map1 = {map = 'Map 1', score1 = '2', score2 = '1'},
			}

			assert.is_nil(processed.extradata.placementinfo)
			assert.are_equal(1, #processed.games)
		end)
	end)
end)
