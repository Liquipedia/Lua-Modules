--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Swiss', function()
	local Array = require('Module:Array')
	local StandingTableLegacySwiss = require('Module:Standings/Table/Legacy/Swiss')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

	describe('tiebreakers', function()
		it('maps the h2h and minileague tiebreakers to h2hlegacy and ml', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'h2h series',
				tiebreaker2 = 'h2h games',
				tiebreaker3 = 'minileague points',
				tiebreaker4 = 'minileague series%',
				tiebreaker5 = 'minileague games',
				tiebreaker6 = 'minileague games won',
			}
			assert.are_same({
				'h2hlegacy.matchscore', 'h2hlegacy.gamescore', 'ml.points', 'ml.matchwinrate', 'ml.gamediff', 'ml.gamewins',
			}, tiebreakers)
		end)

		it('maps the long h2h spellings like h2h', function()
			assert.are_same({
				'h2hlegacy.matchscore', 'h2hlegacy.matchscore', 'h2hlegacy.gamescore', 'h2hlegacy.gamescore',
			}, StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'head-to-head series',
				tiebreaker2 = 'head to head series',
				tiebreaker3 = 'head-to-head games',
				tiebreaker4 = 'head to head games',
			})
		end)

		it('only maps to valid tiebreakers', function()
			local tiebreakers = StandingTableLegacySwiss.parseTiebreaker{
				tiebreaker1 = 'points',
				tiebreaker2 = 'buchholz',
				tiebreaker3 = 'series',
				tiebreaker4 = 'diff',
				tiebreaker5 = 'games won',
				tiebreaker6 = 'games loss',
				tiebreaker7 = 'h2h series',
				tiebreaker8 = 'h2h games',
				tiebreaker9 = 'minileague points',
				tiebreaker10 = 'minileague series%',
				tiebreaker11 = 'minileague games',
				tiebreaker12 = 'minileague games won',
			}
			assert.are_equal(12, #tiebreakers)
			-- Errors on invalid tiebreakers
			for _, tiebreaker in ipairs(tiebreakers) do
				TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
			end
		end)

		it('errors on unknown tiebreakers', function()
			assert.error(function() StandingTableLegacySwiss.parseTiebreaker{tiebreaker1 = 'bogus'} end)
		end)
	end)

	describe('team input', function()
		it('maps r<round>bg<team> to r<round>bg on the opponent', function()
			local args = {
				rounds = '5',
				team1 = 'alpha',
				team2 = 'bravo',
				r3bg1 = 'up',
				r5bg1 = 'stayup',
				r4bg2 = 'down',
			}

			local alpha = StandingTableLegacySwiss.parseTeamInput(args, 1)
			assert.are_equal('alpha', alpha[1])
			assert.are_equal('up', alpha.r3bg)
			assert.are_equal('stayup', alpha.r5bg)
			assert.is_nil(alpha.r4bg)

			local bravo = StandingTableLegacySwiss.parseTeamInput(args, 2)
			assert.are_equal('down', bravo.r4bg)
			assert.is_nil(bravo.r3bg)
		end)

		it('ignores rounds beyond the number of rounds', function()
			local opponent = StandingTableLegacySwiss.parseTeamInput({rounds = '3', team1 = 'alpha', r4bg1 = 'up'}, 1)
			assert.is_nil(opponent.r4bg)
		end)

		it('maps team<team>alias to the aliases of the opponent', function()
			local args = {
				team1 = 'alpha',
				team1alias = 'alpha old, alpha older',
				team2 = 'bravo',
				team2alias = 'bravo old',
				team3 = 'charlie',
			}

			assert.are_equal('alpha old;alpha older', StandingTableLegacySwiss.parseTeamInput(args, 1).aliases)
			assert.are_equal('bravo old', StandingTableLegacySwiss.parseTeamInput(args, 2).aliases)
			assert.is_nil(StandingTableLegacySwiss.parseTeamInput(args, 3).aliases)
		end)
	end)

	describe('solo input', function()
		it('maps r<round>bg<player> to r<round>bg on the opponent', function()
			local args = {rounds = '5', player1 = 'Alpha', p2 = 'Bravo', r3bg1 = 'up', r4bg2 = 'down'}

			local alpha = StandingTableLegacySwiss.parseSoloInput(args, 1)
			assert.are_equal('Alpha', alpha[1])
			assert.are_equal('up', alpha.r3bg)
			assert.is_nil(alpha.r4bg)

			local bravo = StandingTableLegacySwiss.parseSoloInput(args, 2)
			assert.are_equal('down', bravo.r4bg)
			assert.is_nil(bravo.r3bg)
		end)
	end)

	describe('points', function()
		it('uses the legacy defaults', function()
			assert.are_equal('win=3, draw=1, loss=0', StandingTableLegacySwiss.parsePoints{})
		end)

		it('maps win_p, tie_p and lose_p', function()
			assert.are_equal(
				'win=2, draw=0.5, loss=-1',
				StandingTableLegacySwiss.parsePoints{win_p = '2', tie_p = '0.5', lose_p = '-1'}
			)
		end)

		it('converts additive score points to fixed points of a win', function()
			assert.are_equal('win=3, draw=1, loss=0, 2-0=6', StandingTableLegacySwiss.parsePoints{['2-0_p'] = '3'})
			-- compares the scores as numbers
			assert.are_equal('win=3, draw=1, loss=0, 10-2=4', StandingTableLegacySwiss.parsePoints{['10-2_p'] = '1'})
			assert.are_equal(
				'win=2, draw=1, loss=0, 2-0=3.5',
				StandingTableLegacySwiss.parsePoints{win_p = '2', ['2-0_p'] = '1.5'}
			)
		end)

		it('converts additive score points to fixed points of a loss', function()
			assert.are_equal('win=3, draw=1, loss=0, 0-2=1', StandingTableLegacySwiss.parsePoints{['0-2_p'] = '1'})
			assert.are_equal(
				'win=3, draw=1, loss=-1, 1-2=0',
				StandingTableLegacySwiss.parsePoints{lose_p = '-1', ['1-2_p'] = '1'}
			)
		end)

		it('converts additive score points to fixed points of a draw', function()
			assert.are_equal(
				'win=3, draw=2, loss=0, 1-1=3',
				StandingTableLegacySwiss.parsePoints{tie_p = '2', ['1-1_p'] = '1'}
			)
		end)

		it('orders the score points deterministically', function()
			assert.are_equal(
				'win=3, draw=1, loss=0, 0-2=0, 1-1=1, 2-0=3, 2-1=3',
				StandingTableLegacySwiss.parsePoints{['2-1_p'] = '0', ['2-0_p'] = '0', ['1-1_p'] = '0', ['0-2_p'] = '0'}
			)
		end)

		it('ignores unrelated arguments', function()
			assert.are_equal(
				'win=3, draw=1, loss=0',
				StandingTableLegacySwiss.parsePoints{title = 'Swiss', ['2-0'] = '3', ['x-y_p'] = '3'}
			)
		end)

		it('reads score points with decimals only if enabled', function()
			local args = {win_p = '1', tie_p = '0.5', ['1.5-0.5_p'] = '1'}
			assert.are_equal('win=1, draw=0.5, loss=0', StandingTableLegacySwiss.parsePoints(args))
			assert.are_equal('win=1, draw=0.5, loss=0, 1.5-0.5=2',
				StandingTableLegacySwiss.parsePoints(args, {decimalScores = true}))
		end)

		it('maps walkover_lose_p as a bonus on top of lose_p', function()
			assert.are_equal(
				'win=3, draw=1, loss=0, walkoverloss=-1',
				StandingTableLegacySwiss.parsePoints{walkover_lose_p = '-1'}
			)
			assert.are_equal(
				'win=3, draw=1, loss=-1, walkoverloss=-1.5',
				StandingTableLegacySwiss.parsePoints{lose_p = '-1', walkover_lose_p = '-0.5'}
			)
			assert.are_equal(
				'win=3, draw=1, loss=0, otwin=2, otloss=1, walkoverloss=-2, 2-0=4',
				StandingTableLegacySwiss.parsePoints{show_otp = 'true', walkover_lose_p = '-2', ['2-0_p'] = '1'}
			)
		end)

		it('leaves out walkover_lose_p when it is 0', function()
			assert.are_equal('win=3, draw=1, loss=0', StandingTableLegacySwiss.parsePoints{walkover_lose_p = '0'})
			assert.are_equal('win=3, draw=1, loss=0', StandingTableLegacySwiss.parsePoints{walkover_lose_p = ''})
		end)

		it('errors on non numeric values', function()
			assert.error(function() StandingTableLegacySwiss.parsePoints{win_p = 'three'} end)
			assert.error(function() StandingTableLegacySwiss.parsePoints{['2-0_p'] = 'three'} end)
			assert.error(function() StandingTableLegacySwiss.parsePoints{walkover_lose_p = 'one'} end)
		end)

		it('is passed on as the points of the standard parameters', function()
			assert.are_equal(
				'win=3, draw=1, loss=0, 2-0=6',
				StandingTableLegacySwiss.getStandardParameter{['2-0_p'] = '3'}.points
			)
		end)
	end)

	describe('walkover games', function()
		it('maps walkover_win to walkovergames', function()
			assert.are_equal('2', StandingTableLegacySwiss.getStandardParameter{walkover_win = '2'}.walkovergames)
			assert.is_nil(StandingTableLegacySwiss.getStandardParameter{}.walkovergames)
		end)
	end)

	describe('rainbowsix', function()
		local config = StandingTableLegacySwiss.RAINBOWSIX_CONFIG

		it('maps buchholz to the points of the opponents', function()
			local args = {tiebreaker1 = 'points', tiebreaker2 = 'buchholz', tiebreaker3 = 'diff'}
			assert.are_same({'points', 'buchholzpoints', 'gamediff'}, StandingTableLegacySwiss.parseTiebreaker(args, config))
			assert.are_same({'points', 'buchholzpoints', 'rounddiff'},
				StandingTableLegacySwiss.parseTiebreaker(args, config, true))
			assert.are_same({'points', 'buchholz', 'gamediff'}, StandingTableLegacySwiss.parseTiebreaker(args))
			assert.error(function()
				StandingTableLegacySwiss.parseTiebreaker({tiebreaker1 = 'no ot diff'}, config, true)
			end)
		end)

		it('maps the game tiebreakers to rounds when every match is a Bo1', function()
			local args = {
				tiebreaker1 = 'diff',
				tiebreaker2 = 'diff games',
				tiebreaker3 = 'games won',
				tiebreaker4 = 'games loss',
				tiebreaker5 = 'h2h games',
				tiebreaker6 = 'minileague games',
				tiebreaker7 = 'minileague games won',
				tiebreaker8 = 'series',
			}
			assert.are_same(
				{'rounddiff', 'rounddiff', 'roundwins', 'roundlosses', 'h2hlegacy.roundscore', 'ml.rounddiff',
					'ml.roundwins', 'matchscore'},
				StandingTableLegacySwiss.parseTiebreaker(args, config, true)
			)
			assert.are_same(
				{'gamediff', 'gamediff', 'gamewins', 'gamelosses', 'h2hlegacy.gamescore', 'ml.gamediff', 'ml.gamewins',
					'matchscore'},
				StandingTableLegacySwiss.parseTiebreaker(args, config, false)
			)
		end)

		it('only translates the names the swiss table knows', function()
			assert.error(function() StandingTableLegacySwiss.parseTiebreaker({tiebreaker1 = 'games%'}, config, true) end)
			assert.error(function() StandingTableLegacySwiss.parseTiebreaker({tiebreaker1 = 'bogus'}, config) end)
		end)

		it('only maps to valid tiebreakers on rainbowsix', function()
			local inputs = {}
			for index, input in ipairs{'points', 'buchholz', 'series', 'diff', 'diff games', 'games won',
				'games loss', 'h2h series', 'h2h games', 'minileague points', 'minileague series%', 'minileague games',
				'minileague games won'} do
				inputs['tiebreaker' .. index] = input
			end
			for _, isBestOfOne in ipairs{false, true} do
				for _, tiebreaker in ipairs(StandingTableLegacySwiss.parseTiebreaker(inputs, config, isBestOfOne)) do
					TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
				end
			end
		end)

		it('is a Bo1 table only if every match is a Bo1', function()
			assert.is_true(StandingTableLegacySwiss.isBestOfOne{{bestof = 1}, {bestof = '1'}})
			assert.is_false(StandingTableLegacySwiss.isBestOfOne{{bestof = 1}, {bestof = 3}})
			assert.is_false(StandingTableLegacySwiss.isBestOfOne{})
		end)

		it('ignores the matches without a best of, like walkovers', function()
			assert.is_true(StandingTableLegacySwiss.isBestOfOne{{bestof = 1}, {bestof = 0}, {bestof = '0'}, {}})
			assert.is_false(StandingTableLegacySwiss.isBestOfOne{{bestof = 0}, {}})
			assert.is_false(StandingTableLegacySwiss.isBestOfOne{{bestof = 1}, {bestof = 0}, {bestof = 3}})
		end)

		it('counts walkover_win as rounds on Bo1 tables', function()
			local parameters = StandingTableLegacySwiss.getStandardParameter{walkover_win = '7'}
			local bestOfOne = config.adjustParameters(parameters, {walkover_win = '7'}, true)
			assert.are_same({nil, '7'}, {bestOfOne.walkovergames, bestOfOne.walkoverrounds})
			assert.are_equal('7', parameters.walkovergames)
			assert.are_equal(parameters, config.adjustParameters(parameters, {walkover_win = '7'}, false))
		end)

		describe('standings input', function()
			local StandingTable = require('Module:Standings/Table')
			local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

			---@param id string
			---@param bestOf integer
			---@param section string
			---@return table
			local function matchRecord(id, bestOf, section)
				return {
					match2id = id,
					bestof = bestOf,
					extradata = {matchsection = section},
					match2opponents = {{type = 'team', template = 'team liquid'}, {type = 'team', template = 'heroic'}},
				}
			end

			---@param matchRecords table[]
			---@return table
			local function standingsInput(matchRecords)
				stub(mw.ext.LiquipediaDB, 'lpdb', matchRecords)
				stub(StandingTable, 'fromTemplate')
				StandingTableLegacySwiss.rainbowsix{rounds = '2', team1 = 'team liquid', team2 = 'heroic',
					tiebreaker1 = 'buchholz', tiebreaker2 = 'diff', walkover_win = '7'}
				---@diagnostic disable-next-line: undefined-field
				local input = StandingTable.fromTemplate.calls[1].vals[1]
				---@diagnostic disable-next-line: undefined-field
				StandingTable.fromTemplate:revert()
				---@diagnostic disable-next-line: undefined-field
				mw.ext.LiquipediaDB.lpdb:revert()
				return input
			end

			before_each(function()
				TeamTemplateMock.setUp()
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
			end)

			it('passes the Bo1 mapping to the standings', function()
				local input = standingsInput{matchRecord('a', 1, 'Round 1'), matchRecord('b', 1, 'Round 2')}
				assert.are_same({'buchholzpoints', 'rounddiff'}, input.tiebreakers)
				assert.are_same({'7', 'a', 'b'}, {input.walkoverrounds, input.round1.matches, input.round2.matches})
				assert.is_nil(input.walkovergames)
			end)

			it('detects the format from the matches of the rounds', function()
				local bestOfOne = {matchRecord('a', 1, 'Round 1'), matchRecord('b', 1, 'Round 2')}
				assert.are_same({'buchholzpoints', 'rounddiff'}, standingsInput(Array.extend(bestOfOne,
					matchRecord('c', 3, 'Round 3'), matchRecord('d', 3, 'Playoffs'))).tiebreakers)
				assert.are_same({'buchholzpoints', 'gamediff'},
					standingsInput(Array.extend(bestOfOne, matchRecord('c', 3, 'Round 2'))).tiebreakers)
			end)
		end)
	end)
end)
