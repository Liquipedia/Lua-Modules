--- Triple Comment to Enable our LLS Plugin
--[[
Tests for Module:MatchGroup/Display/Helper.

`mergeBracketResetMatch` folds a grand finals and its bracket reset into one match for the bracket
display. It is presentation rather than bracket topology, which is why it lives here.
]]

insulate('MatchGroup/Display/Helper', function()
	describe('mergeBracketResetMatch', function()
		it('folds the reset scores in as the second scores and appends its games', function()
			local DisplayHelper = require('Module:MatchGroup/Display/Helper')
			local match = {
				matchId = 'R03-M001',
				opponents = {{name = 'A', score = 2, status = 'S'}, {name = 'B', score = 3, status = 'S'}},
				games = {{map = 'M1'}},
			}
			local merged = DisplayHelper.mergeBracketResetMatch(match, {
				opponents = {{score = 1, status = 'S', placement = 2}, {score = 3, status = 'S', placement = 1}},
				games = {{map = 'M2'}},
			})

			assert.are_equal('R03-M001', merged.matchId)
			assert.are_equal(2, merged.opponents[1].score)
			assert.are_equal(1, merged.opponents[1].score2)
			assert.are_equal(2, merged.opponents[1].placement2)
			assert.are_equal(3, merged.opponents[2].score2)
			assert.are_same({{map = 'M1'}, {map = 'M2'}}, merged.games)
			-- the original is left alone
			assert.are_equal(1, #match.games)
			assert.is_nil(match.opponents[1].score2)
		end)
	end)
end)
