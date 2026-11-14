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

		it('routes 3-4 solo opponents through the FFA parser', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1', score = 123},
				opponent2 = {type = 'solo', name = 'Player2', score = 122},
				opponent3 = {type = 'solo', name = 'Player3', score = 121},
				opponent4 = {type = 'solo', name = 'Player4', score = 97},
			}

			assert.are_same({123, 122, 121, 97}, {
				processed.opponents[1].score,
				processed.opponents[2].score,
				processed.opponents[3].score,
				processed.opponents[4].score,
			})
			assert.are_same({1, 2, 3, 4}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
				processed.opponents[4].placement,
			})
			assert.are_equal(2, processed.opponents[1].extradata.winners)
		end)

		it('routes 3-4 duo opponents through the FFA parser', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'duo', p1 = 'Player1', p2 = 'Player2', score = 3},
				opponent2 = {type = 'duo', p1 = 'Player3', p2 = 'Player4', score = 2},
				opponent3 = {type = 'duo', p1 = 'Player5', p2 = 'Player6', score = 1},
			}

			assert.are_equal('duo', processed.opponents[1].type)
			assert.are_same({1, 2, 3}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
			})
		end)

		it('supports placement-only matches without scores', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				finished = true,
				winner = 1,
				opponent1 = {type = 'solo', name = 'Player1', placement = 1},
				opponent2 = {type = 'solo', name = 'Player2', placement = 2},
				opponent3 = {type = 'solo', name = 'Player3', placement = 3},
				opponent4 = {type = 'solo', name = 'Player4', placement = 4},
			}

			assert.are_same({1, 2, 3, 4}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
				processed.opponents[4].placement,
			})
		end)

		it('does not assign placements without manual placement or scores', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1'},
				opponent2 = {type = 'solo', name = 'Player2'},
				opponent3 = {type = 'solo', name = 'Player3'},
				opponent4 = {type = 'solo', name = 'Player4'},
			}

			for _, opponent in ipairs(processed.opponents) do
				assert.is_nil(opponent.score)
				assert.is_nil(opponent.placement)
			end
		end)

		it('stores advances flags on opponents', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1', score = 3, advances = true},
				opponent2 = {type = 'solo', name = 'Player2', score = 2, advances = false},
				opponent3 = {type = 'solo', name = 'Player3', score = 1},
			}

			assert.is_true(processed.opponents[1].extradata.advances)
			assert.is_false(processed.opponents[2].extradata.advances)
			assert.is_nil(processed.opponents[3].extradata.advances)
		end)

		it('uses position as placement', function()
			local processed = CustomMatchGroupInput.processMatch{
				date = '2024-01-01',
				opponent1 = {type = 'solo', name = 'Player1', position = 1},
				opponent2 = {type = 'solo', name = 'Player2', position = 2},
				opponent3 = {type = 'solo', name = 'Player3', position = 3},
				opponent4 = {type = 'solo', name = 'Player4', position = 4},
			}

			assert.are_same({1, 2, 3, 4}, {
				processed.opponents[1].placement,
				processed.opponents[2].placement,
				processed.opponents[3].placement,
				processed.opponents[4].placement,
			})
		end)

		it('keeps 2-player matches on the standard parser', function()
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

insulate('Trackmania bracket opponent entry', function()
	setup(function() SetActiveWiki('trackmania') end)
	teardown(function() SetActiveWiki() end)

	---@param placement integer
	---@param winners integer?
	---@param score number?
	---@param advances boolean?
	---@return table
	local function opponent(placement, winners, score, advances)
		return {
			type = 'solo',
			name = 'Player1',
			placement = placement,
			score = score,
			advances = advances,
			extradata = {winners = winners},
			players = {{name = 'Player1', pageName = 'Player1', displayName = 'Player1'}},
		}
	end

	it('bolds the configured winners and shows ordinal scores', function()
		local OpponentEntry = require('Module:Widget/Match/Bracket/OpponentEntry/Custom')

		local function render(opponentData)
			return tostring(OpponentEntry{
				opponent = opponentData,
				height = 30,
				displayType = 'bracket',
			})
		end

		local highlighted = render(opponent(2, 2, 98))
		local notHighlighted = render(opponent(3, 2, 97))
		local standardWinner = render(opponent(1, nil, 99))
		local standardLoser = render(opponent(2, nil, 98))
		local noScore = render(opponent(2, 2, nil))
		local advanced = render(opponent(3, 2, 97, true))

		assert.is_truthy(highlighted:find('font-weight:bold', 1, true))
		assert.is_truthy(highlighted:find('<b>', 1, true))
		assert.is_falsy(notHighlighted:find('font-weight:bold', 1, true))
		assert.is_truthy(standardWinner:find('font-weight:bold', 1, true))
		assert.is_falsy(standardLoser:find('font-weight:bold', 1, true))
		assert.is_truthy(noScore:find('2<sup>nd</sup>', 1, true))
		assert.is_truthy(advanced:find('brkts-opponent-win', 1, true))
		assert.is_truthy(advanced:find('font-weight:bold', 1, true))
	end)
end)
