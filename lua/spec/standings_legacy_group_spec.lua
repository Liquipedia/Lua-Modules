--- Triple Comment to Enable our LLS Plugin
describe('Standings Legacy Group', function()
	local Array = require('Module:Array')
	local StandingTableLegacyGroup = require('Module:Standings/Table/Legacy/Group')
	local Table = require('Module:Table')
	local TiebreakerFactory = require('Module:Standings/Tiebreaker/Factory')

	local NOW = 1700000000
	local DAY = 86400

	describe('tiebreakers', function()
		it('defaults to the legacy order', function()
			assert.are_same({
				'matchscore', 'gamediff', 'h2hlegacy.matchscore', 'h2hlegacy.gamescore', 'gamewins', 'gamelosses',
			}, StandingTableLegacyGroup.parseTiebreakers{})
		end)

		it('puts points first in the default order with show_p', function()
			assert.are_equal('points', StandingTableLegacyGroup.parseTiebreakers{show_p = 'true'}[1])
		end)

		it('only maps to valid tiebreakers', function()
			local tiebreakers = StandingTableLegacyGroup.parseTiebreakers{
				tiebreaker1 = 'points',
				tiebreaker2 = 'series',
				tiebreaker3 = 'series%',
				tiebreaker4 = 'series diff',
				tiebreaker5 = 'diff',
				tiebreaker6 = 'games won',
				tiebreaker7 = 'games loss',
				tiebreaker8 = 'head-to-head series',
				tiebreaker9 = 'head to head games',
				tiebreaker10 = 'series won',
				tiebreaker11 = 'series loss',
				tiebreaker12 = 'games%',
				tiebreaker13 = 'games',
				tiebreaker14 = 'h2h diff',
			}
			assert.are_same({
				'points', 'matchscore', 'matchwinrate', 'matchdiff', 'gamediff', 'gamewins', 'gamelosses',
				'h2hlegacy.matchscore', 'h2hlegacy.gamescore', 'matchwins', 'matchlosses', 'gamewinrate', 'gamediff',
				'ml.rounddiff',
			}, tiebreakers)
			for _, tiebreaker in ipairs(tiebreakers) do
				TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
			end
		end)

		it('errors on unknown tiebreakers', function()
			assert.error(function() StandingTableLegacyGroup.parseTiebreakers{tiebreaker1 = 'bogus'} end)
		end)

		it('applies the tiebreakers and defaults of the wiki', function()
			local config = {
				tiebreakers = {diff = 'rounddiff'},
				defaultTiebreakers = {'series', 'diff'},
				defaultPointsTiebreakers = {'points'},
			}
			assert.are_same({'rounddiff', 'matchscore'},
				StandingTableLegacyGroup.parseTiebreakers({tiebreaker1 = 'diff', tiebreaker2 = 'series'}, config))
			assert.are_same({'matchscore', 'rounddiff'}, StandingTableLegacyGroup.parseTiebreakers({}, config))
			assert.are_same({'points'}, StandingTableLegacyGroup.parseTiebreakers({show_p = 'true'}, config))
		end)

		it('only maps to valid tiebreakers on valorant', function()
			local config = StandingTableLegacyGroup.VALORANT_CONFIG
			local args = {}
			for input in pairs(config.tiebreakers) do
				table.insert(args, input)
			end
			local tiebreakers = StandingTableLegacyGroup.parseTiebreakers(
				Table.map(args, function(index, input) return 'tiebreaker' .. index, input end), config
			)
			Array.extendWith(tiebreakers, StandingTableLegacyGroup.parseTiebreakers({}, config))
			for _, tiebreaker in ipairs(tiebreakers) do
				TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
			end
		end)
	end)

	describe('rounds', function()
		it('has a single final round without round dates', function()
			assert.are_same({{index = 0}}, StandingTableLegacyGroup.parseRounds({}, NOW))
		end)

		it('orders the rounds by their date and adds the final round after them', function()
			local rounds = StandingTableLegacyGroup.parseRounds({
				r1date = NOW - 2 * DAY,
				round2edate = NOW - 3 * DAY,
			}, NOW)
			assert.are_same({
				{index = 2, endTime = NOW - 3 * DAY},
				{index = 1, endTime = NOW - 2 * DAY},
				{index = 0},
			}, rounds)
		end)

		it('reads a round with both date and edate once', function()
			local rounds = StandingTableLegacyGroup.parseRounds({r1date = NOW - DAY, r1edate = NOW - DAY}, NOW)
			assert.are_same({{index = 1, endTime = NOW - DAY}, {index = 0}}, rounds)
		end)

		it('has no final round while a round is still to come', function()
			local rounds = StandingTableLegacyGroup.parseRounds({r1date = NOW - DAY, r2date = NOW + DAY}, NOW)
			assert.are_same({1, 2}, {rounds[1].index, rounds[2].index})
			assert.are_equal(2, #rounds)
		end)

		it('drops the rounds after edate and ends the final round at it', function()
			local rounds = StandingTableLegacyGroup.parseRounds({
				r1date = NOW - 3 * DAY,
				r2date = NOW - DAY,
				edate = NOW - 2 * DAY,
			}, NOW)
			assert.are_same({{index = 1, endTime = NOW - 3 * DAY}, {index = 0, endTime = NOW - 2 * DAY}}, rounds)
		end)

		it('assigns the matches to the first round ending after them', function()
			local rounds = {{index = 1, endTime = 100}, {index = 2, endTime = 200}, {index = 0}}
			local matchesByRound = StandingTableLegacyGroup.groupMatchesByRound(rounds, {
				{match2id = 'a', date = 50},
				{match2id = 'b', date = 100},
				{match2id = 'c', date = 150},
				{match2id = 'd', date = 300},
			})
			assert.are_same({'a', 'b'}, matchesByRound[1])
			assert.are_same({'c'}, matchesByRound[2])
			assert.are_same({'d'}, matchesByRound[3])
		end)

		it('assumes the rounds are finished', function()
			assert.are_same(
				{title = 'Week 1', started = true, finished = true, matches = 'a,b'},
				StandingTableLegacyGroup.parseRoundInput({roundtitle = 'Week'}, 1, {'a', 'b'})
			)
		end)

		it('assigns matches after the last round to it', function()
			local matchesByRound = StandingTableLegacyGroup.groupMatchesByRound(
				{{index = 1, endTime = 100}}, {{match2id = 'a', date = 300}}
			)
			assert.are_same({'a'}, matchesByRound[1])
		end)
	end)

	describe('team input', function()
		local rounds = {{index = 2, endTime = 100}, {index = 1, endTime = 200}, {index = 0}}

		it('maps the per round inputs to the rounds in date order', function()
			local args = {
				team1 = 'alpha',
				r1bg1 = 'up',
				round2bg1 = 'stay',
				bg1 = 'proceed',
				r2dq2 = 'true',
				team2 = 'bravo',
				dq2 = 'true',
			}

			local alpha = StandingTableLegacyGroup.parseTeamInput(args, 1, rounds)
			assert.are_same({'alpha', 'stay', 'up', 'proceed'}, {alpha[1], alpha.r1bg, alpha.r2bg, alpha.r3bg})
			assert.is_nil(alpha.dq)

			assert.are_equal(1, StandingTableLegacyGroup.parseTeamInput(args, 2, rounds).dq)
		end)

		it('applies the final round inputs to the last round without a final round', function()
			local alpha = StandingTableLegacyGroup.parseTeamInput(
				{team1 = 'alpha', bg1 = 'up', dq1 = 'true'}, 1, {{index = 1, endTime = 100}, {index = 2, endTime = 200}}
			)
			assert.are_equal('up', alpha.r2bg)
			assert.are_equal(2, alpha.dq)
		end)

		it('maps temp_p and temp_tie to adjustments from their round', function()
			local alpha = StandingTableLegacyGroup.parseTeamInput(
				{team1 = 'alpha', temp_p1 = '2', r1temp_p1 = '-1', temp_tie1 = '1'}, 1, rounds
			)
			assert.are_same({-1, 2, 1}, {alpha.r2points, alpha.r3points, alpha.r3tiebreaker})
			assert.is_nil(alpha.startingpoints)
		end)

		it('maps team<N>alias to the aliases of the opponent', function()
			assert.are_equal('alpha old;alpha older', StandingTableLegacyGroup.parseTeamInput(
				{team1 = 'alpha', team1alias = 'alpha old, alpha older'}, 1, rounds
			).aliases)
		end)
	end)

	describe('solo input', function()
		local rounds = {{index = 1, endTime = 100}, {index = 0}}

		it('reads player<N> and p<N> with their flag and link', function()
			local args = {
				player1 = 'Alpha',
				player1flag = 'se',
				player1link = 'Alpha (player)',
				p2 = 'Bravo',
				p2flag = 'fi',
			}

			local alpha = StandingTableLegacyGroup.parseSoloInput(args, 1, rounds)
			assert.are_same({'solo', 'Alpha', 'se', 'Alpha (player)'}, {alpha.type, alpha[1], alpha.flag, alpha.link})

			local bravo = StandingTableLegacyGroup.parseSoloInput(args, 2, rounds)
			assert.are_same({'Bravo', 'fi'}, {bravo[1], bravo.flag})

			assert.is_nil(StandingTableLegacyGroup.parseSoloInput(args, 3, rounds))
		end)

		it('maps the round inputs of the player', function()
			local alpha = StandingTableLegacyGroup.parseSoloInput(
				{p1 = 'Alpha', r1bg1 = 'up', bg1 = 'proceed', r1dq1 = 'true', temp_p1 = '2'}, 1, rounds
			)
			assert.are_same({'up', 'proceed', 1, 2}, {alpha.r1bg, alpha.r2bg, alpha.dq, alpha.r2points})
		end)
	end)

	describe('standard parameters', function()
		it('imports the opponents from the matches only if none are listed', function()
			assert.is_true(StandingTableLegacyGroup.getStandardParameter({}, {}).importopponents)
			assert.is_false(StandingTableLegacyGroup.getStandardParameter({}, {{}}).importopponents)
		end)

		it('is a group table that is exclusive by default', function()
			local parameters = StandingTableLegacyGroup.getStandardParameter({title = 'Group A'}, {})
			assert.are_same({'group', true, 'Group A'}, {parameters.tabletype, parameters.exclusive, parameters.title})
		end)

		it('maps the legacy points', function()
			assert.are_equal('win=3, draw=1, loss=0, 2-0=4',
				StandingTableLegacyGroup.getStandardParameter({['2-0_p'] = '1'}, {}).points)
		end)

		it('maps the legacy walkover loss points on top of the loss points', function()
			assert.are_equal('win=3, draw=1, loss=-1, walkoverloss=-2',
				StandingTableLegacyGroup.getStandardParameter({lose_p = '-1', walkover_lose_p = '-1'}, {}).points)
		end)

		it('splits the walkover rounds of the match over its maps', function()
			local function walkoverRounds(args)
				return StandingTableLegacyGroup.getStandardParameter(args, {}).walkoverrounds
			end
			assert.are_same(
				{13, 13, 26, 6},
				{
					walkoverRounds{walkover_rounds_win = '26', walkover_win = '2'},
					walkoverRounds{walkover_rounds_win = '13', walkover_win = '1'},
					walkoverRounds{walkover_rounds_win = '26'},
					walkoverRounds{walkover_rounds_win = '13', walkover_win = '2'},
				}
			)
			assert.is_nil(walkoverRounds{})
		end)

		it('resets the tiebreakers only with a h2hcs tiebreaker', function()
			local config = StandingTableLegacyGroup.VALORANT_CONFIG
			local function needsReset(args)
				return StandingTableLegacyGroup.needsTiebreakerReset(StandingTableLegacyGroup.parseTiebreakers(args, config))
			end
			assert.is_true(needsReset{})
			assert.is_true(needsReset{tiebreaker1 = 'series', tiebreaker2 = 'h2h series'})
			assert.is_nil(needsReset{show_p = 'true'})
			assert.is_nil(needsReset{tiebreaker1 = 'series', tiebreaker2 = 'h2h games', tiebreaker3 = 'diff'})
			assert.is_nil(StandingTableLegacyGroup.needsTiebreakerReset(StandingTableLegacyGroup.parseTiebreakers{}))
		end)
	end)

	describe('classic', function()
		local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

		before_each(function()
			TeamTemplateMock.setUp()
			stub(mw.ext.LiquipediaDB, 'lpdb', {})
			stub(mw.ext.LiquipediaDB, 'lpdb_standingstable')
			stub(mw.ext.LiquipediaDB, 'lpdb_standingsentry')
		end)

		after_each(function()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_standingstable:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_standingsentry:revert()
			TeamTemplateMock.tearDown()
		end)

		it('renders and stores a group table', function()
			local html = tostring(StandingTableLegacyGroup.classic{
				title = 'Group A',
				team1 = 'team liquid',
				team2 = 'mouz',
				pbg1 = 'up',
				pbg2 = 'down',
				tiebreaker1 = 'diff',
			})
			assert.is_truthy(html:find('standings-group', 1, true))
			assert.is_truthy(html:find('Group A', 1, true))
			---@diagnostic disable-next-line: undefined-field
			local storedTable = mw.ext.LiquipediaDB.lpdb_standingstable.calls[1].vals[2]
			assert.are_equal('league', storedTable.type)
		end)

		it('renders and stores a solo group table', function()
			StandingTableLegacyGroup.solo{
				title = 'Group A',
				p1 = 'Alpha',
				p1flag = 'se',
				player2 = 'Bravo',
				temp_win_m2 = '1',
			}
			---@diagnostic disable-next-line: undefined-field
			local entries = require('Module:Array').map(mw.ext.LiquipediaDB.lpdb_standingsentry.calls, function(call)
				return call.vals[2]
			end)
			local firstEntry = require('Module:Array').find(entries, function(entry) return entry.slotindex == 1 end)
			assert.are_same({'solo', 'Bravo'}, {firstEntry.opponenttype, firstEntry.opponentname})
		end)

		it('counts the adjustments in the standings', function()
			StandingTableLegacyGroup.classic{
				team1 = 'team liquid',
				team2 = 'mouz',
				temp_win_m2 = '1',
				temp_tie2 = '1',
			}
			---@diagnostic disable-next-line: undefined-field
			local entries = require('Module:Array').map(mw.ext.LiquipediaDB.lpdb_standingsentry.calls, function(call)
				return call.vals[2]
			end)
			local firstEntry = require('Module:Array').find(entries, function(entry) return entry.slotindex == 1 end)
			local scoreboard = require('Module:Json').parse(firstEntry.scoreboard)
			assert.are_equal('mouz', firstEntry.opponenttemplate:match('^mouz'))
			assert.are_same({3, 1}, {scoreboard.points, scoreboard.match.w})
		end)
	end)

	describe('adjustments', function()
		local rounds = {{index = 1, endTime = 100}, {index = 0}}

		it('maps the match and game record adjustments', function()
			assert.are_same({
				r1matchwins = 1,
				r1points = 3,
				r2matchdraws = 2,
				r2matchlosses = 1,
				r2gamewins = 3,
				r2gamelosses = 4,
				r1roundwins = 13,
				r2roundlosses = 26,
			}, StandingTableLegacyGroup.parseAdjustments({
				r1temp_win_m1 = '1',
				temp_tie_m1 = '2',
				temp_lose_m1 = '1',
				temp_win_g1 = '3',
				temp_lose_g1 = '4',
				r1temp_win_r1 = '13',
				temp_lose_r1 = '26',
				tie_p = '0',
			}, 1, rounds))
		end)

		it('counts the adjusted matches towards the points', function()
			assert.are_same(
				{r2matchwins = 2, r2matchdraws = 1, r2matchlosses = 1, r2points = 4},
				StandingTableLegacyGroup.parseAdjustments(
					{temp_win_m1 = '2', temp_tie_m1 = '1', temp_lose_m1 = '1', win_p = '2', lose_p = '-1'}, 1, rounds
				)
			)
		end)

		it('only reads the adjustments of the opponent', function()
			assert.are_same({}, StandingTableLegacyGroup.parseAdjustments({temp_p2 = '1', temp_p12 = '1'}, 1, rounds))
		end)

		it('errors on non numeric adjustments', function()
			assert.error(function() StandingTableLegacyGroup.parseAdjustments({temp_win_m1 = 'one'}, 1, rounds) end)
		end)
	end)

	describe('rainbowsix', function()
		local config = StandingTableLegacyGroup.RAINBOWSIX_CONFIG

		---@param args table
		---@param isBestOfOne boolean
		---@return table
		local function parameters(args, isBestOfOne)
			return StandingTableLegacyGroup.adjustRainbowSixParameters(
				StandingTableLegacyGroup.getStandardParameter(args, {}), args, isBestOfOne
			)
		end

		it('maps the rainbowsix tiebreakers', function()
			assert.are_same(
				{'gamediff', 'rounddiff', 'roundwins', 'roundlosses', 'roundwinrate', 'ml.points', 'ml.points',
					'ml.matchwinrate', 'ml.gamediff', 'ml.gamewins'},
				StandingTableLegacyGroup.parseTiebreakers({
					tiebreaker1 = 'games diff',
					tiebreaker2 = 'rdiff',
					tiebreaker3 = 'rounds won',
					tiebreaker4 = 'rounds loss',
					tiebreaker5 = 'rounds%',
					tiebreaker6 = 'minileague points',
					tiebreaker7 = 'minileague ot points',
					tiebreaker8 = 'minileague series%',
					tiebreaker9 = 'minileague games',
					tiebreaker10 = 'minileague games won',
				}, config)
			)
			assert.error(function() StandingTableLegacyGroup.parseTiebreakers({tiebreaker1 = 'h2h'}, config) end)
		end)

		it('only maps to valid tiebreakers on rainbowsix', function()
			for _, isBestOfOne in ipairs{false, true} do
				local inputs = Array.filter(
					Array.extractKeys(Table.merge(config.tiebreakers, config.bestOfOneTiebreakers)),
					function(input) return (pcall(StandingTableLegacyGroup.parseTiebreakers, {tiebreaker1 = input}, config)) end
				)
				local tiebreakers = StandingTableLegacyGroup.parseTiebreakers(
					Table.map(inputs, function(index, input) return 'tiebreaker' .. index, input end), config, isBestOfOne
				)
				Array.extendWith(tiebreakers, StandingTableLegacyGroup.parseTiebreakers({}, config, isBestOfOne))
				for _, tiebreaker in ipairs(tiebreakers) do
					TiebreakerFactory.validateAndNormalizeInput(tiebreaker)
				end
			end
		end)

		it('maps the game tiebreakers to rounds when every match is a Bo1', function()
			local args = {
				tiebreaker1 = 'diff',
				tiebreaker2 = 'games won',
				tiebreaker3 = 'games loss',
				tiebreaker4 = 'games%',
				tiebreaker5 = 'h2h games',
				tiebreaker6 = 'minileague games',
				tiebreaker7 = 'minileague games won',
				tiebreaker8 = 'series',
			}
			assert.are_same(
				{'rounddiff', 'roundwins', 'roundlosses', 'roundwinrate', 'h2hlegacy.roundscore', 'ml.rounddiff',
					'ml.roundwins', 'matchscore'},
				StandingTableLegacyGroup.parseTiebreakers(args, config, true)
			)
			assert.are_same(
				{'gamediff', 'gamewins', 'gamelosses', 'gamewinrate', 'h2hlegacy.gamescore', 'ml.gamediff',
					'ml.gamewins', 'matchscore'},
				StandingTableLegacyGroup.parseTiebreakers(args, config, false)
			)
			assert.are_same(
				{'matchscore', 'rounddiff', 'h2hlegacy.matchscore', 'h2hlegacy.roundscore', 'roundwins', 'roundlosses'},
				StandingTableLegacyGroup.parseTiebreakers({}, config, true)
			)
			assert.are_same(
				{'gamediff', 'gamewins'},
				StandingTableLegacyGroup.parseTiebreakers({tiebreaker1 = 'diff', tiebreaker2 = 'games won'}, nil, true)
			)
		end)

		it('only translates the names the group table knows', function()
			assert.error(function()
				StandingTableLegacyGroup.parseTiebreakers({tiebreaker1 = 'diff games'}, config, true)
			end)
		end)

		it('counts walkover_win as rounds on Bo1 tables', function()
			local bestOfOne = parameters({walkover_win = '7'}, true)
			assert.are_same({nil, '7'}, {bestOfOne.walkovergames, bestOfOne.walkoverrounds})
			local bestOfThree = parameters({walkover_win = '2'}, false)
			assert.are_same({'2', nil}, {bestOfThree.walkovergames, bestOfThree.walkoverrounds})
		end)

		it('counts walkover_win_r per walkover map', function()
			local function walkovers(args, isBestOfOne)
				local adjusted = parameters(args, isBestOfOne)
				return {adjusted.walkovergames, adjusted.walkoverrounds}
			end
			assert.are_same({'2', '7'}, walkovers({walkover_win = '2', walkover_win_r = '7'}, false))
			assert.are_same({'2', '7'}, walkovers({walkover_win = '2', walkover_win_r = '7', walkover_rounds_win = '26'}, false))
			assert.are_same({'2', 13}, walkovers({walkover_win = '2', walkover_rounds_win = '26'}, false))
			assert.are_same({nil, '7'}, walkovers({walkover_win = '1', walkover_win_r = '7'}, true))
			assert.are_same({nil, '7'}, walkovers({walkover_win = '7', walkover_rounds_win = '7'}, true))
		end)

		it('only tracks overtime on Bo1 tables', function()
			local bestOfOne = parameters({show_otp = 'true', otw_p = '2.5'}, true)
			assert.is_true(bestOfOne.overtime)
			assert.are_equal('win=3, draw=1, loss=0, otwin=2.5, otloss=1', bestOfOne.points)
			local mixed = parameters({show_otp = 'true'}, false)
			assert.is_false(mixed.overtime)
			assert.are_equal('win=3, draw=1, loss=0', mixed.points)
			assert.is_false(parameters({}, true).overtime)
		end)

		it('reads the regulation rounds from maplength on overtime tables', function()
			assert.are_equal('10', parameters({show_otp = 'true', maplength = '10'}, true).regulationrounds)
			assert.is_nil(parameters({show_otp = 'true'}, true).regulationrounds)
			assert.is_nil(parameters({maplength = '10'}, true).regulationrounds)
			assert.is_nil(parameters({show_otp = 'true', maplength = '10'}, false).regulationrounds)
		end)

		it('scores a 2-1 as overtime with maplength 2', function()
			local adjusted = parameters({show_otp = 'true', maplength = '2'}, false)
			assert.is_false(adjusted.overtime)
			assert.are_equal('win=3, draw=1, loss=0, 1-2=1, 2-1=2', adjusted.points)
			assert.are_equal('win=2, draw=1, loss=-1, 1-2=0, 2-1=4',
				parameters({show_otp = 'true', maplength = '2', win_p = '2', lose_p = '-1', otw_p = '3', ['2-1_p'] = '1',
					otl_p = '0'}, false).points)
			assert.are_equal('win=3, draw=1, loss=0', parameters({maplength = '2'}, false).points)
		end)

		describe('standings input', function()
			local StandingTable = require('Module:Standings/Table')
			local StandingTableLegacyNext = require('Module:Standings/Table/Legacy/Next')
			local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

			---@param template1 string
			---@param template2 string
			---@param bestOf integer
			---@return table
			local function matchRecord(template1, template2, bestOf)
				return {
					match2id = template1 .. template2,
					date = '2024-01-01 00:00:00',
					bestof = bestOf,
					match2opponents = {{type = 'team', template = template1}, {type = 'team', template = template2}},
				}
			end

			---@param args table
			---@param matchRecords table[]
			---@return table
			local function standingsInput(args, matchRecords)
				stub(StandingTableLegacyNext, 'fetchMatches', matchRecords)
				stub(StandingTable, 'fromTemplate')
				StandingTableLegacyGroup.rainbowsix(args)
				---@diagnostic disable-next-line: undefined-field
				local input = StandingTable.fromTemplate.calls[1].vals[1]
				---@diagnostic disable-next-line: undefined-field
				StandingTable.fromTemplate:revert()
				---@diagnostic disable-next-line: undefined-field
				StandingTableLegacyNext.fetchMatches:revert()
				return input
			end

			before_each(function()
				TeamTemplateMock.setUp()
			end)

			after_each(function()
				TeamTemplateMock.tearDown()
			end)

			it('passes the Bo1 mapping to the standings', function()
				local input = standingsInput(
					{team1 = 'team liquid', team2 = 'heroic', walkover_win = '7', show_otp = 'true'},
					{matchRecord('team liquid', 'heroic', 1), matchRecord('heroic', 'team liquid', 1)}
				)
				assert.are_same(
					{'matchscore', 'rounddiff', 'h2hlegacy.matchscore', 'h2hlegacy.roundscore', 'roundwins', 'roundlosses'},
					input.tiebreakers
				)
				assert.are_same({true, '7'}, {input.overtime, input.walkoverrounds})
				assert.is_nil(input.walkovergames)
			end)

			it('detects the format from the matches the standings count', function()
				local function tiebreakers(args, records)
					return standingsInput(Table.merge({team1 = 'team liquid', team2 = 'heroic'}, args), records).tiebreakers
				end
				local groupMatch = matchRecord('team liquid', 'heroic', 1)
				local outsiderMatch = matchRecord('team liquid', 'team secret', 3)
				local unrelatedMatch = matchRecord('team secret', 'team bds', 3)
				local nonExclusive = {exclusive = 'false'}
				assert.are_equal('rounddiff', tiebreakers({}, {groupMatch, outsiderMatch})[2])
				assert.are_equal('rounddiff', tiebreakers(nonExclusive, {groupMatch, unrelatedMatch})[2])
				assert.are_equal('gamediff', tiebreakers(nonExclusive, {groupMatch, outsiderMatch})[2])
				assert.are_equal('gamediff', tiebreakers({}, {groupMatch, matchRecord('heroic', 'team liquid', 3)})[2])
				assert.are_equal('rounddiff', tiebreakers({team2alias = 'team secret'}, {
					groupMatch, matchRecord('team liquid', 'team bds', 3), matchRecord('team liquid', 'team secret', 1),
				})[2])
			end)

			it('counts the game adjustments as rounds on Bo1 tables', function()
				local args = {team1 = 'team liquid', team2 = 'heroic', temp_win_g1 = '7', temp_lose_g1 = '5', temp_win_r1 = '1'}
				local bestOfOne = standingsInput(args, {matchRecord('team liquid', 'heroic', 1)})
				assert.are_same({8, 5}, {bestOfOne[1].r1roundwins, bestOfOne[1].r1roundlosses})
				assert.is_nil(bestOfOne[1].r1gamewins)
				local bestOfThree = standingsInput(args, {matchRecord('team liquid', 'heroic', 3)})
				assert.are_same({7, 5, 1}, {bestOfThree[1].r1gamewins, bestOfThree[1].r1gamelosses, bestOfThree[1].r1roundwins})
			end)
		end)

		it('translates the adjustments of the rounds', function()
			assert.are_same(
				{'team liquid', r1roundwins = 15, r2roundlosses = 1, r1bg = 'up', r1matchwins = 1},
				StandingTableLegacyGroup.translateAdjustments(
					{'team liquid', r1gamewins = 2, r1roundwins = 13, r2gamelosses = 1, r1bg = 'up', r1matchwins = 1},
					{gamewins = 'roundwins', gamelosses = 'roundlosses'}
				)
			)
		end)
	end)

	describe('ties', function()
		it('turns draws on with ties=true and auto detects them otherwise', function()
			local function matchDraws(args)
				return StandingTableLegacyGroup.getStandardParameter(args, {}).matchdraws
			end
			assert.is_true(matchDraws{ties = 'true'})
			assert.is_nil(matchDraws{ties = 'false'})
			assert.is_nil(matchDraws{})
		end)
	end)
end)
