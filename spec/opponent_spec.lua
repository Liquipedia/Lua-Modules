--- Triple Comment to Enable our LLS Plugin
describe('opponent', function()
	local Config = require('test_assets.opponent_test_config')
	local Opponent = require('Module:Opponent')

	describe('is party', function()
		it('check', function()
			assert.is_true(Opponent.typeIsParty(Opponent.solo))
			assert.is_true(Opponent.typeIsParty(Opponent.duo))
			assert.is_true(Opponent.typeIsParty(Opponent.trio))
			assert.is_true(Opponent.typeIsParty(Opponent.quad))
			assert.is_false(Opponent.typeIsParty(Opponent.literal))
			assert.is_false(Opponent.typeIsParty(Opponent.team))
			assert.is_false(Opponent.typeIsParty())
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_false(Opponent.typeIsParty('someBs'))
		end)
	end)

	describe('party size', function()
		it('check', function()
			assert.are_equal(1, Opponent.partySize(Opponent.solo))
			assert.are_equal(2, Opponent.partySize(Opponent.duo))
			assert.are_equal(3, Opponent.partySize(Opponent.trio))
			assert.are_equal(4, Opponent.partySize(Opponent.quad))
			assert.are_equal(nil, Opponent.partySize(Opponent.literal))
			assert.are_equal(nil, Opponent.partySize(Opponent.team))
			assert.are_equal(nil, Opponent.partySize())
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.are_equal(nil, Opponent.partySize('someBs'))
		end)
	end)

	describe('blank opponent', function()
		it('check', function()
			assert.are_same(Config.blankSolo, Opponent.blank(Opponent.solo))
			assert.are_same(Config.blankDuo, Opponent.blank(Opponent.duo))
			assert.are_same(Config.blankTeam, Opponent.blank(Opponent.team))
			assert.are_same(Config.blankLiteral, Opponent.blank(Opponent.literal))
			assert.are_same(Config.blankLiteral, Opponent.blank())
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.are_same(Config.blankLiteral, Opponent.blank('someBs'))
		end)
	end)

	describe('tbd opponent', function()
		it('check', function()
			assert.are_same(Config.tbdSolo, Opponent.tbd(Opponent.solo))
			assert.are_same(Config.tbdDuo, Opponent.tbd(Opponent.duo))
			assert.are_same(Config.tbdTeam, Opponent.tbd(Opponent.team))
			assert.are_same(Config.tbdLiteral, Opponent.tbd(Opponent.literal))
			assert.are_same(Config.tbdLiteral, Opponent.tbd())
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.are_same(Config.tbdLiteral, Opponent.tbd('someBs'))
		end)
	end)

	describe('is tbd', function()
		it('check', function()
			assert.is_true(Opponent.isTbd(Config.byeLiteral))
			assert.is_false(Opponent.isTbd(Config.byeTeam))
			assert.is_true(Opponent.isTbd(Config.blankLiteral))
			assert.is_true(Opponent.isTbd(Config.blankSolo))
			assert.is_true(Opponent.isTbd(Config.blankDuo))
			assert.is_true(Opponent.isTbd(Config.blankTeam))
			assert.is_true(Opponent.isTbd(Config.tbdLiteral))
			assert.is_true(Opponent.isTbd(Config.tbdSolo))
			assert.is_true(Opponent.isTbd(Config.tbdDuo))
			assert.is_true(Opponent.isTbd(Config.filledLiteral))
			assert.is_false(Opponent.isTbd(Config.filledTeam))
			assert.is_false(Opponent.isTbd(Config.filledSolo))
			assert.is_false(Opponent.isTbd(Config.filledDuo))
			assert.error(Opponent.isTbd) --misisng input
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.error(function() return Opponent.isTbd('someBs') end)
		end)
	end)

	describe('is empty', function()
		it('check', function()
			assert.is_false(Opponent.isEmpty(Config.byeLiteral))
			assert.is_false(Opponent.isEmpty(Config.byeTeam))
			assert.is_true(Opponent.isEmpty(Config.blankLiteral))
			assert.is_true(Opponent.isEmpty(Config.blankSolo))
			assert.is_true(Opponent.isEmpty(Config.blankDuo))
			assert.is_true(Opponent.isEmpty(Config.emptyTeam))
			assert.is_false(Opponent.isEmpty(Config.blankTeam))
			assert.is_false(Opponent.isEmpty(Config.tbdLiteral))
			assert.is_false(Opponent.isEmpty(Config.tbdSolo))
			assert.is_false(Opponent.isEmpty(Config.tbdDuo))
			assert.is_false(Opponent.isEmpty(Config.filledLiteral))
			assert.is_false(Opponent.isEmpty(Config.filledTeam))
			assert.is_false(Opponent.isEmpty(Config.filledSolo))
			assert.is_false(Opponent.isEmpty(Config.filledDuo))
			assert.is_true(Opponent.isEmpty())
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_true(Opponent.isEmpty('someBs')) --invalid input
		end)
	end)

	describe('is bye', function()
		it('check', function()
			assert.is_false(Opponent.isBye(Config.blankLiteral))
			assert.is_false(Opponent.isBye(Config.blankSolo))
			assert.is_false(Opponent.isBye(Config.blankDuo))
			assert.is_false(Opponent.isBye(Config.emptyTeam))
			assert.is_false(Opponent.isBye(Config.blankTeam))
			assert.is_false(Opponent.isBye(Config.tbdLiteral))
			assert.is_false(Opponent.isBye(Config.tbdSolo))
			assert.is_false(Opponent.isBye(Config.tbdDuo))
			assert.is_false(Opponent.isBye(Config.filledLiteral))
			assert.is_false(Opponent.isBye(Config.filledTeam))
			assert.is_false(Opponent.isBye(Config.filledSolo))
			assert.is_false(Opponent.isBye(Config.filledDuo))
			assert.is_true(Opponent.isBye(Config.byeLiteral))
			assert.is_true(Opponent.isBye(Config.byeTeam))
			assert.error(Opponent.isBye)
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_false(Opponent.isBye('someBs'))
		end)
	end)

	describe('read type', function()
		it('check', function()
			---intended missing input
			---@diagnostic disable-next-line: missing-parameter
			assert.are_equal(nil, Opponent.readType())
			assert.are_equal(nil, Opponent.readType('someBs'))
			assert.are_equal(Opponent.solo, Opponent.readType('solo'))
			assert.are_equal(Opponent.duo, Opponent.readType('duo'))
			assert.are_equal(Opponent.trio, Opponent.readType('trio'))
			assert.are_equal(Opponent.quad, Opponent.readType('quad'))
			assert.are_equal(Opponent.team, Opponent.readType('team'))
			assert.are_equal(Opponent.literal, Opponent.readType('literal'))
		end)
	end)

	describe('coerce', function()
		it('check', function()
			local coerce = function(opponent)
				Opponent.coerce(opponent)
				return opponent
			end

			assert.are_same(Config.blankLiteral, coerce{})
			assert.are_same(Config.blankLiteral, coerce{type = Opponent.literal})
			assert.are_same(Config.blankTeam, coerce{type = Opponent.team})
			assert.are_same(Config.blankSolo, coerce{type = Opponent.solo})
			assert.are_same(Config.blankDuo, coerce{type = Opponent.duo})
			assert.are_same({type = Opponent.duo, players = {{displayName = 'test'}, {displayName = ''}}},
				coerce{type = Opponent.duo, players = {{displayName = 'test'}}})
		end)
	end)

	describe('to name', function()
		it('check', function()
			assert.are_equal('test', Opponent.toName(Config.filledLiteral))
			assert.are_equal('test', Opponent.toName(Config.filledSolo))
			assert.are_equal('test / test2', Opponent.toName(Config.filledDuo))
			assert.error(Opponent.toName)
			---intended bad input
			---@diagnostic disable-next-line: param-type-mismatch
			assert.are_equal(nil, Opponent.toName('someBs'))
			--can not test team type due to missing team templates on commons
		end)
	end)

	describe('read args', function()
		it('check', function()
			assert.are_same({
					type = Opponent.solo,
					players = {
						{displayName = 'test', flag = 'Germany', pageName = 'testLink', team = 'mouz'}
					}
				},
				Opponent.readOpponentArgs{type = Opponent.solo, p1 = 'test', flag = 'de', link = 'testLink', team = 'mouz'})
			assert.are_same({
				type = Opponent.duo,
				players = {
					{displayName = 'test', flag = 'Germany', pageName = 'testLink', team = 'mouz'},
					{displayName = 'test2', flag = 'Austria'},
				}
			}, Opponent.readOpponentArgs{p1 = 'test', p1flag = 'de', p1link = 'testLink', p1team = 'mouz',
				p2 = 'test2', p2flag = 'at', type = Opponent.duo})
			assert.are_same({name = 'test', type = Opponent.literal},
				Opponent.readOpponentArgs{type = Opponent.literal, name = 'test'})
			assert.are_same({template = 'test', type = Opponent.team},
				Opponent.readOpponentArgs{type = Opponent.team, template = 'test'})
			assert.are_same({name = 'test', type = Opponent.literal},
				Opponent.readOpponentArgs{type = Opponent.literal, 'test'})
			assert.are_same({template = 'test', type = Opponent.team},
				Opponent.readOpponentArgs{type = Opponent.team, 'test'})
		end)
	end)

	describe('from match2 record', function()
		it('check', function()
			assert.are_same({name = '', type = Opponent.literal},
				Opponent.fromMatch2Record(Config.exampleMatch2RecordLiteral))
			assert.are_same({template = 'exon march 2020', type = Opponent.team},
				Opponent.fromMatch2Record(Config.exampleMatch2RecordTeam))
			assert.are_same({
					type = Opponent.solo,
					players = {
						{displayName = 'Krystianer', flag = 'Poland', pageName = 'Krystianer'}}
				},
				Opponent.fromMatch2Record(Config.exampleMatch2RecordSolo))
			assert.are_same({
				type = Opponent.duo,
				players = {
					{displayName = 'Semper', flag = 'Canada', pageName = 'Semper'},
					{displayName = 'Jig', flag = 'Canada', pageName = 'Jig'},
				}
			}, Opponent.fromMatch2Record(Config.exampleMatch2RecordDuo))
		end)
	end)

	describe('to lpdb struct', function()
		it('check', function()
			assert.are_same({opponentname = '', opponenttype = Opponent.literal},
				Opponent.toLpdbStruct(Opponent.fromMatch2Record(Config.exampleMatch2RecordLiteral) --[[@as standardOpponent]]))
			assert.are_same({
				opponentname = 'Krystianer',
				opponenttype = Opponent.solo,
				opponentplayers = {
					p1 = 'Krystianer',
					p1dn = 'Krystianer',
					p1flag = 'Poland',
				}
			},
				Opponent.toLpdbStruct(Opponent.fromMatch2Record(Config.exampleMatch2RecordSolo) --[[@as standardOpponent]]))
			assert.are_same({
				opponentname = 'Jig / Semper',
				opponenttype = Opponent.duo,
				opponentplayers = {
					p1 = 'Semper',
					p1dn = 'Semper',
					p1flag = 'Canada',
					p2 = 'Jig',
					p2dn = 'Jig',
					p2flag = 'Canada',
				}
			}, Opponent.toLpdbStruct(Opponent.fromMatch2Record(Config.exampleMatch2RecordDuo) --[[@as standardOpponent]]))
			--can not test for team opponent due to missing team templates
		end)
	end)

	describe('from lpdb struct', function()
		it('check', function()
			local opponent = Opponent.fromMatch2Record(Config.exampleMatch2RecordLiteral) --[[@as standardOpponent]]
			assert.are_same(opponent, Opponent.fromLpdbStruct(Opponent.toLpdbStruct(opponent)))
			opponent = Opponent.fromMatch2Record(Config.exampleMatch2RecordSolo) --[[@as standardOpponent]]
			assert.are_same(opponent, Opponent.fromLpdbStruct(Opponent.toLpdbStruct(opponent)))
			opponent = Opponent.fromMatch2Record(Config.exampleMatch2RecordDuo) --[[@as standardOpponent]]
			assert.are_same(opponent, Opponent.fromLpdbStruct(Opponent.toLpdbStruct(opponent)))
			--can not test for team opponent due to missing team templates
		end)
	end)

	--not testing `resolve` due to missing team templates and lpdb data
end)
