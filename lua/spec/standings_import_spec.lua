--- Triple Comment to Enable our LLS Plugin
local TeamTemplateMock = require('wikis.commons.Mock.TeamTemplate')

describe('Standings import from matches', function()
	local StandingsParseLpdb = require('Module:Standings/Parse/Lpdb')
	local Array = require('Module:Array')
	local Table = require('Module:Table')

	---@param props {matchId: string, opponents: {template: string?, name: string, score: integer,
	---placement: integer, type: string?}[], winner: integer?, finished: boolean?, bestof: integer?,
	---games: {winner: integer, status: string?, scores: integer[]}[]?}
	---@return table
	local function match2Record(props)
		return {
			match2id = props.matchId,
			date = '2024-01-05',
			dateexact = '1',
			finished = props.finished ~= false and '1' or '0',
			winner = props.winner and tostring(props.winner) or '',
			bestof = tostring(props.bestof or 3),
			extradata = {},
			match2bracketdata = {},
			match2games = Array.map(props.games or {}, function(game)
				return {winner = tostring(game.winner), status = game.status or '', scores = game.scores, extradata = {}}
			end),
			match2opponents = Array.map(props.opponents, function(opponentSpec)
				return {
					type = opponentSpec.type or 'team',
					template = opponentSpec.template,
					name = opponentSpec.name,
					score = opponentSpec.score,
					status = 'S',
					placement = opponentSpec.placement,
					extradata = {},
					match2players = {},
				}
			end),
		}
	end

	local function stubMatchQuery(records)
		local recordsById = {}
		for _, record in ipairs(records) do
			recordsById[record.match2id] = record
		end
		return stub(mw.ext.LiquipediaDB, 'lpdb', function(tableName, parameters)
			if tableName ~= 'match2' then
				return {}
			end
			-- return the records the conditions ask for, mimicking the LPDB matchid filter
			local found = {}
			for matchId, record in pairs(recordsById) do
				if parameters.conditions:find(matchId, 1, true) then
					table.insert(found, record)
				end
			end
			return found
		end)
	end

	local function swissScoreMapper(opponent)
		return opponent.placement == 1 and 1 or 0
	end

	local function findOpponent(opponents, name)
		return Array.find(opponents, function(opponentData)
			return opponentData.opponent.name == name
		end)
	end

	before_each(function()
		TeamTemplateMock.setUp()
	end)

	after_each(function()
		TeamTemplateMock.tearDown()
		---@diagnostic disable-next-line: undefined-field
		mw.ext.LiquipediaDB.lpdb:revert()
	end)

	it('returns no opponents without matches', function()
		stubMatchQuery{}
		local opponents = StandingsParseLpdb.importFromMatches(
			{{roundNumber = 1, matches = {}}}, swissScoreMapper, {}, {importOpponents = true}
		)
		assert.are_same({}, opponents)
	end)

	it('builds opponents with per round scoreboards and accumulated matches', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'tt9 esports 2022', name = 'TT9 Esports', score = 0, placement = 2},
			}},
			match2Record{matchId = 'M2', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M2'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		assert.are_equal(3, #opponents)

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_equal(1, heroic.rounds[1].scoreboard.points)
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_equal('M1', heroic.rounds[1].matchId)
		assert.are_equal('', heroic.rounds[1].specialstatus)
		assert.are_equal(1, #heroic.rounds[1].matches)

		assert.are_equal(1, heroic.rounds[2].scoreboard.points)
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
		assert.are_equal('M2', heroic.rounds[2].matchId)
		-- matches accumulate over rounds
		assert.are_equal(2, #heroic.rounds[2].matches)
		assert.are_equal('M1', heroic.rounds[2].matches[1].matchId)
		assert.are_equal('M2', heroic.rounds[2].matches[2].matchId)

		local tt9 = findOpponent(opponents, 'TT9 Esports')
		assert.are_equal(0, tt9.rounds[1].scoreboard.points)
		assert.are_same({w = 0, d = 0, l = 1}, tt9.rounds[1].scoreboard.match)
		-- TT9 did not play round 2
		assert.are_equal('nc', tt9.rounds[2].specialstatus)
		assert.is_nil(tt9.rounds[2].matchId)

		local wolves = findOpponent(opponents, 'Wolves Esports')
		assert.are_equal('nc', wolves.rounds[1].specialstatus)
		assert.are_same({w = 0, d = 0, l = 1}, wolves.rounds[2].scoreboard.match)
	end)

	it('does not count unfinished matches in the match scoreboard', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', finished = false, opponents = {
				{template = 'heroic', name = 'Heroic', score = 1, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 0, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_equal('M1', heroic.rounds[1].matchId)
	end)

	it('counts draws when the match has no winner', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 0, opponents = {
				{template = 'heroic', name = 'Heroic', score = 1, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 1},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 0, d = 1, l = 0}, heroic.rounds[1].scoreboard.match)
	end)

	it('counts a match in every round it is assigned to', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M1'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
	end)

	it('collects every match an opponent plays in the same round', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
			match2Record{matchId = 'M2', winner = 2, opponents = {
				{template = 'heroic', name = 'Heroic', score = 1, placement = 2},
				{template = 'wolves esports', name = 'Wolves Esports', score = 2, placement = 1},
			}},
			match2Record{matchId = 'M3', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'tt9 esports 2022', name = 'TT9 Esports', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1', 'M2'}},
			{roundNumber = 2, matches = {'M3'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		local function matchIds(matches)
			local ids = Array.map(matches, function(match) return match.matchId end)
			table.sort(ids)
			return ids
		end

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({'M1', 'M2'}, matchIds(heroic.rounds[1].matches))
		assert.are_same({w = 1, d = 0, l = 1}, heroic.rounds[1].scoreboard.match)
		assert.are_equal(1, heroic.rounds[1].scoreboard.points)
		assert.is_true(heroic.rounds[1].matchId == 'M1' or heroic.rounds[1].matchId == 'M2')
		-- the matches of earlier rounds stay in the list of later rounds
		assert.are_same({'M1', 'M2', 'M3'}, matchIds(heroic.rounds[2].matches))
		assert.are_equal('M3', heroic.rounds[2].matchId)

		local wolves = findOpponent(opponents, 'Wolves Esports')
		assert.are_same({'M1', 'M2'}, matchIds(wolves.rounds[1].matches))
		assert.are_same({'M1', 'M2'}, matchIds(wolves.rounds[2].matches))
	end)

	it('records the points of every match', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
			match2Record{matchId = 'M2', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M2'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({M1 = 1}, heroic.rounds[1].matchPoints)
		-- cumulative, like matches
		assert.are_same({M1 = 1, M2 = 1}, heroic.rounds[2].matchPoints)

		local wolves = findOpponent(opponents, 'Wolves Esports')
		assert.are_same({M1 = 0}, wolves.rounds[1].matchPoints)
		assert.are_same({M1 = 0, M2 = 0}, wolves.rounds[2].matchPoints)
	end)

	it('does not record points for matches the score mapper has no points for', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, function(opponent)
			return opponent.placement == 1 and 3 or nil
		end, {}, {importOpponents = true})

		assert.are_same({M1 = 3}, findOpponent(opponents, 'Heroic').rounds[1].matchPoints)
		assert.are_same({}, findOpponent(opponents, 'Wolves Esports').rounds[1].matchPoints)
	end)

	it('keeps counting a match assigned to several rounds in every round', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M1'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_equal(1, #heroic.rounds[1].matches)
		assert.are_equal(2, #heroic.rounds[2].matches)
		assert.are_same({M1 = 1}, heroic.rounds[1].matchPoints)
		assert.are_same({M1 = 1}, heroic.rounds[2].matchPoints)
		assert.are_equal('M1', heroic.rounds[2].matchId)
	end)

	it('drops tbd opponents', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
				{template = 'tbd', name = 'TBD', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper, {}, {importOpponents = true})

		assert.are_equal(1, #opponents)
		assert.are_equal('Heroic', opponents[1].opponent.name)
	end)

	it('applies a points based score mapper', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', winner = 1, opponents = {
				{template = 'heroic', name = 'Heroic', score = 13, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 7, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, function(opponent)
			if opponent.status == 'S' then
				return tonumber(opponent.score)
			end
			return nil
		end,
		{}, {importOpponents = true})

		assert.are_equal(13, findOpponent(opponents, 'Heroic').rounds[1].scoreboard.points)
		assert.are_equal(7, findOpponent(opponents, 'Wolves Esports').rounds[1].scoreboard.points)
	end)

	it('applies aliases correctly', function()
		stubMatchQuery{
			match2Record{matchId = 'M1', finished = true, opponents = {
				{template = 'team liquid 2023', name = 'Team Liquid', score = 1, placement = 1},
				{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
			}},
		}

		local opponents = StandingsParseLpdb.importFromMatches({
			{roundNumber = 1, matches = {'M1'}},
		}, swissScoreMapper, {
			{
				aliases = {{template = 'team liquid 2023', name = 'Team Liquid', type = 'team', extradata = {}}},
				opponent = {template = 'heroic', name = 'Heroic', type = 'team', extradata = {}},
			},
			{
				aliases = {},
				opponent = {template = 'wolves esports', name = 'Wolves Esports', type = 'team', extradata = {}},
			}
		})

		local heroic = findOpponent(opponents, 'Heroic')
		assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
		assert.are_equal('M1', heroic.rounds[1].matchId)
	end)

	describe('overtime', function()
		local Info = require('Module:Info')
		local StandingsParseWiki = require('Module:Standings/Parse/Wiki')
		local originalStandingsConfig

		local rounds = {{roundNumber = 1, matches = {'M1'}}, {roundNumber = 2, matches = {'M2'}}}

		before_each(function()
			originalStandingsConfig = Info.config.standings
			Info.config.standings = {overtime = {regulationRounds = 12}}
		end)

		after_each(function()
			Info.config.standings = originalStandingsConfig
		end)

		---M1 is won in regulation (7-3), M2 is won in overtime (7-6 for Wolves)
		---@param overrides {m1: table?, m2: table?}?
		local function stubRegulationAndOvertimeMatch(overrides)
			overrides = overrides or {}
			stubMatchQuery{
				match2Record(Table.merge({matchId = 'M1', winner = 1, bestof = 1, opponents = {
					{template = 'heroic', name = 'Heroic', score = 1, placement = 1},
					{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
				}, games = {{winner = 1, scores = {7, 3}}}}, overrides.m1)),
				match2Record(Table.merge({matchId = 'M2', winner = 2, bestof = 1, opponents = {
					{template = 'heroic', name = 'Heroic', score = 0, placement = 2},
					{template = 'wolves esports', name = 'Wolves Esports', score = 1, placement = 1},
				}, games = {{winner = 2, scores = {6, 7}}}}, overrides.m2)),
			}
		end

		it('keeps overtime results out of the match scoreboard', function()
			stubRegulationAndOvertimeMatch()

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {
				importOpponents = true,
				overtime = true,
			})

			local heroic = findOpponent(opponents, 'Heroic')
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
			assert.are_same({w = 0, l = 0}, heroic.rounds[1].scoreboard.overtime)
			assert.are_same({w = 0, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
			assert.are_same({w = 0, l = 1}, heroic.rounds[2].scoreboard.overtime)

			local wolves = findOpponent(opponents, 'Wolves Esports')
			assert.are_same({w = 0, d = 0, l = 1}, wolves.rounds[1].scoreboard.match)
			assert.are_same({w = 0, l = 0}, wolves.rounds[1].scoreboard.overtime)
			assert.are_same({w = 0, d = 0, l = 0}, wolves.rounds[2].scoreboard.match)
			assert.are_same({w = 1, l = 0}, wolves.rounds[2].scoreboard.overtime)
		end)

		it('detects overtime from the rounds, not from the match score', function()
			-- M2 is a Bo1 that ended 1-0 in maps, which is why the match score can not be used
			stubRegulationAndOvertimeMatch{m2 = {games = {{winner = 2, scores = {5, 7}}}}}

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {
				importOpponents = true,
				overtime = true,
			})

			local wolves = findOpponent(opponents, 'Wolves Esports')
			assert.are_same({w = 1, d = 0, l = 0}, wolves.rounds[2].scoreboard.match)
			assert.are_same({w = 0, l = 0}, wolves.rounds[2].scoreboard.overtime)
		end)

		it('awards 3/2/1/0 points', function()
			stubRegulationAndOvertimeMatch()

			local opponents = StandingsParseLpdb.importFromMatches(
				rounds, StandingsParseWiki.makeScoringFunction('swiss', {}, true), {}, {
					importOpponents = true,
					overtime = true,
				}
			)

			local heroic = findOpponent(opponents, 'Heroic')
			local wolves = findOpponent(opponents, 'Wolves Esports')
			assert.are_equal(3, heroic.rounds[1].scoreboard.points)
			assert.are_equal(1, heroic.rounds[2].scoreboard.points)
			assert.are_equal(0, wolves.rounds[1].scoreboard.points)
			assert.are_equal(2, wolves.rounds[2].scoreboard.points)
		end)

		it('awards no points for unfinished matches', function()
			stubRegulationAndOvertimeMatch{m2 = {finished = false, winner = 0}}

			local opponents = StandingsParseLpdb.importFromMatches(
				rounds, StandingsParseWiki.makeScoringFunction('swiss', {}, true), {}, {
					importOpponents = true,
					overtime = true,
				}
			)

			local heroic = findOpponent(opponents, 'Heroic')
			local wolves = findOpponent(opponents, 'Wolves Esports')
			assert.are_equal(0, heroic.rounds[2].scoreboard.points or 0)
			assert.are_equal(0, wolves.rounds[2].scoreboard.points or 0)
			assert.are_same({w = 0, l = 0}, wolves.rounds[2].scoreboard.overtime)
		end)

		it('is unchanged without overtime', function()
			stubRegulationAndOvertimeMatch()

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {
				importOpponents = true,
			})

			local heroic = findOpponent(opponents, 'Heroic')
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
			assert.are_same({w = 0, d = 0, l = 1}, heroic.rounds[2].scoreboard.match)
			assert.is_nil(heroic.rounds[1].scoreboard.overtime)
			assert.is_nil(heroic.rounds[2].scoreboard.overtime)
			assert.are_equal(1, heroic.rounds[1].scoreboard.points)
			assert.are_equal(0, heroic.rounds[2].scoreboard.points)
		end)

		it('requires Bo1 matches', function()
			stubRegulationAndOvertimeMatch{m2 = {bestof = 3}}

			assert.error(function()
				StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {
					importOpponents = true,
					overtime = true,
				})
			end)
		end)

		it('allows matches without a bestof', function()
			stubRegulationAndOvertimeMatch{m2 = {bestof = 0}}

			assert.has_no.error(function()
				StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {
					importOpponents = true,
					overtime = true,
				})
			end)
		end)

		it('allows non-Bo1 matches without overtime', function()
			stubRegulationAndOvertimeMatch{m2 = {bestof = 3}}

			assert.has_no.error(function()
				StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {importOpponents = true})
			end)
		end)

		it('counts draws as regulation results', function()
			stubMatchQuery{
				match2Record{matchId = 'M1', winner = 0, bestof = 1, opponents = {
					{template = 'heroic', name = 'Heroic', score = 0, placement = 1},
					{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 1},
				}, games = {{winner = 0, scores = {7, 7}}}},
			}

			local opponents = StandingsParseLpdb.importFromMatches({rounds[1]}, swissScoreMapper, {}, {
				importOpponents = true,
				overtime = true,
			})

			local heroic = findOpponent(opponents, 'Heroic')
			assert.are_same({w = 0, d = 1, l = 0}, heroic.rounds[1].scoreboard.match)
			assert.are_same({w = 0, l = 0}, heroic.rounds[1].scoreboard.overtime)
		end)
	end)

	describe('opponent based filtering', function()
		---@param opponentName string
		---@param template string
		local function manualOpponent(opponentName, template)
			return {opponent = {type = 'team', template = template, name = opponentName, extradata = {}}}
		end

		--- M1 is between two opponents of the standings, M2 only has one of them
		local function stubInternalAndExternalMatch()
			stubMatchQuery{
				match2Record{matchId = 'M1', winner = 1, opponents = {
					{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
					{template = 'wolves esports', name = 'Wolves Esports', score = 0, placement = 2},
				}},
				match2Record{matchId = 'M2', winner = 1, opponents = {
					{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
					{template = 'tt9 esports 2022', name = 'TT9 Esports', score = 0, placement = 2},
				}},
			}
		end

		local rounds = {
			{roundNumber = 1, matches = {'M1'}},
			{roundNumber = 2, matches = {'M2'}},
		}

		local standingsOpponents = {
			manualOpponent('Heroic', 'heroic'),
			manualOpponent('Wolves Esports', 'wolves esports'),
		}

		it('counts matches with a single standings opponent when non-exclusive', function()
			stubInternalAndExternalMatch()

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, standingsOpponents, {
				exclusive = false,
				importOpponents = false,
			})

			local heroic = findOpponent(opponents, 'Heroic')
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
			assert.are_equal('M2', heroic.rounds[2].matchId)
		end)

		it('ignores matches with a single standings opponent when exclusive', function()
			stubInternalAndExternalMatch()

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, standingsOpponents, {
				exclusive = true,
				importOpponents = false,
			})

			local heroic = findOpponent(opponents, 'Heroic')
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
			assert.are_same({w = 0, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
			assert.are_equal('nc', heroic.rounds[2].specialstatus)
			assert.is_nil(heroic.rounds[2].matchId)
			assert.is_nil(findOpponent(opponents, 'TT9 Esports'))
		end)

		it('resolves aliases before filtering when exclusive', function()
			stubInternalAndExternalMatch()

			local opponentsWithAlias = {
				manualOpponent('Heroic', 'heroic'),
				manualOpponent('Wolves Esports', 'wolves esports'),
			}
			opponentsWithAlias[2].aliases = {
				{type = 'team', template = 'tt9 esports 2022', name = 'TT9 Esports', extradata = {}},
			}

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, opponentsWithAlias, {
				exclusive = true,
				importOpponents = false,
			})

			local wolves = findOpponent(opponents, 'Wolves Esports')
			assert.are_same({w = 0, d = 0, l = 1}, wolves.rounds[1].scoreboard.match)
			assert.are_same({w = 0, d = 0, l = 1}, wolves.rounds[2].scoreboard.match)
			assert.are_equal('M2', wolves.rounds[2].matchId)
		end)

		it('treats imported opponents as part of the standings when exclusive', function()
			stubInternalAndExternalMatch()

			local opponents = StandingsParseLpdb.importFromMatches(rounds, swissScoreMapper, {}, {
				exclusive = true,
				importOpponents = true,
			})

			local heroic = findOpponent(opponents, 'Heroic')
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[1].scoreboard.match)
			assert.are_same({w = 1, d = 0, l = 0}, heroic.rounds[2].scoreboard.match)
			assert.is_not_nil(findOpponent(opponents, 'TT9 Esports'))
		end)

		it('ignores matches against literal opponents when exclusive', function()
			stubMatchQuery{
				match2Record{matchId = 'M1', winner = 1, opponents = {
					{template = 'heroic', name = 'Heroic', score = 2, placement = 1},
					{type = 'literal', name = 'Qualifier Winner', score = 0, placement = 2},
				}},
			}

			local opponents = StandingsParseLpdb.importFromMatches({
				{roundNumber = 1, matches = {'M1'}},
			}, swissScoreMapper, {manualOpponent('Heroic', 'heroic')}, {
				exclusive = true,
				importOpponents = true,
			})

			assert.are_same({}, opponents)
		end)
	end)
end)
