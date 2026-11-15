--- Triple Comment to Enable our LLS Plugin

--- The fixtures below name only the fields each test is about, rather than whole records.
---@diagnostic disable: missing-fields

--[[
Tests for Module:MatchGroup/Util/Bracket, the bracket model.

Bracket data records, topology, coordinates and the id namespace that addresses a match inside its
match group. A matchlist counts as a bracket here, which is why the flat match id forms live with
the bracket ones.
]]

insulate('MatchGroup/Util/Bracket', function()
	describe('bracketDataFromRecord', function()
		it('returns an empty table when there is no data', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({}, BracketUtil.bracketDataFromRecord(nil))
		end)

		it('reads matchlist bracket data', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketData = BracketUtil.bracketDataFromRecord{
				type = 'matchlist',
				header = 'Round 1',
				inheritedheader = 'Group A',
				title = 'A Title',
				dateheader = 'true',
				matchpage = 'Some/Page',
			}

			assert.are_same({
				type = 'matchlist',
				header = 'Round 1',
				inheritedHeader = 'Group A',
				title = 'A Title',
				dateHeader = 'true',
				matchPage = 'Some/Page',
			}, bracketData)
		end)

		it('treats anything that is not a bracket as a matchlist', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_equal('matchlist', BracketUtil.bracketDataFromRecord{header = 'x'}.type)
		end)

		it('reads bracket bracket data', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketData = BracketUtil.bracketDataFromRecord{
				type = 'bracket',
				header = 'Semifinals',
				bracketreset = 'R03-M001',
				thirdplace = 'RxMTP',
				upperMatchId = 'R02-M001',
				qualwinLiteral = 'Qualified',
				qualloseLiteral = 'Eliminated',
				lowerMatchIds = {'R01-M001', 'R01-M002'},
			}

			assert.are_equal('bracket', bracketData.type)
			assert.are_equal('Semifinals', bracketData.header)
			assert.are_equal('R03-M001', bracketData.bracketResetMatchId)
			assert.are_equal('RxMTP', bracketData.thirdPlaceMatchId)
			assert.are_equal('R02-M001', bracketData.upperMatchId)
			assert.are_equal('Qualified', bracketData.qualWinLiteral)
			assert.are_equal('Eliminated', bracketData.qualLoseLiteral)
			assert.are_same({'R01-M001', 'R01-M002'}, bracketData.lowerMatchIds)
			assert.are_equal(0, bracketData.qualSkip)
			assert.are_equal(0, bracketData.skipRound)
		end)

		it('derives the qualification flags from the advance spots', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketData = BracketUtil.bracketDataFromRecord{
				type = 'bracket',
				qualwin = 'true',
				quallose = 'true',
			}

			assert.is_true(bracketData.qualWin)
			assert.is_true(bracketData.qualLose)
			assert.are_equal('qualify', bracketData.advanceSpots[1].type)
			assert.are_equal('qualify', bracketData.advanceSpots[2].type)
		end)

		it('reads qualskip and skipround as numbers, including the true spelling', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local fromStrings = BracketUtil.bracketDataFromRecord{
				type = 'bracket', qualskip = 'true', skipround = 'true',
			}
			assert.are_equal(1, fromStrings.qualSkip)
			assert.are_equal(1, fromStrings.skipRound)

			local fromNumbers = BracketUtil.bracketDataFromRecord{
				type = 'bracket', qualskip = '2', skipround = '3',
			}
			assert.are_equal(2, fromNumbers.qualSkip)
			assert.are_equal(3, fromNumbers.skipRound)
		end)

		it('converts the coordinate indexes from zero based to one based', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketData = BracketUtil.bracketDataFromRecord{
				type = 'bracket',
				coordinates = {roundIndex = 0, sectionIndex = 1, roundCount = 3, depth = 2},
			}

			assert.are_equal(1, bracketData.coordinates.roundIndex)
			assert.are_equal(2, bracketData.coordinates.sectionIndex)
			-- only keys ending in Index shift, counts and depths are left alone
			assert.are_equal(3, bracketData.coordinates.roundCount)
			assert.are_equal(2, bracketData.coordinates.depth)
		end)
	end)

	describe('bracketDataToRecord', function()
		it('round trips a bracket bracket data', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local record = BracketUtil.bracketDataToRecord{
				type = 'bracket',
				header = 'Semifinals',
				bracketResetMatchId = 'R03-M001',
				thirdPlaceMatchId = 'RxMTP',
				upperMatchId = 'R02-M001',
				lowerMatchIds = {'R01-M001', 'R01-M002'},
				qualWin = true,
				qualLose = false,
				qualSkip = 0,
				skipRound = 2,
				coordinates = {sectionIndex = 1, sectionCount = 2, roundIndex = 2},
			}

			assert.are_equal('bracket', record.type)
			assert.are_equal('R03-M001', record.bracketreset)
			assert.are_equal('RxMTP', record.thirdplace)
			assert.are_equal('R01-M002', record.tolower)
			assert.are_equal('R01-M001', record.toupper)
			assert.are_equal('true', record.quallose == nil and 'true' or 'set')
			assert.are_equal('true', record.qualwin)
			assert.is_nil(record.qualskip)
			assert.are_equal(2, record.skipround)
			assert.are_equal('upper', record.bracketsection)
			-- the indexes go back to zero based
			assert.are_equal(0, record.coordinates.sectionIndex)
			assert.are_equal(1, record.coordinates.roundIndex)
		end)
	end)

	describe('computeLowerMatchIdsFromLegacy', function()
		it('reads toupper before tolower and skips empty ones', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({'R02-M001', 'R02-M002'},
				BracketUtil.computeLowerMatchIdsFromLegacy{toupper = 'R02-M001', tolower = 'R02-M002'})
			assert.are_same({'R02-M002'},
				BracketUtil.computeLowerMatchIdsFromLegacy{toupper = '', tolower = 'R02-M002'})
			assert.are_same({}, BracketUtil.computeLowerMatchIdsFromLegacy{})
		end)
	end)

	describe('autoAssignLowerEdges', function()
		it('centres the lower matches when there are fewer of them than opponents', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({{lowerMatchIndex = 1, opponentIndex = 2}}, BracketUtil.autoAssignLowerEdges(1, 3))
			assert.are_same({
				{lowerMatchIndex = 1, opponentIndex = 1},
				{lowerMatchIndex = 2, opponentIndex = 2},
			}, BracketUtil.autoAssignLowerEdges(2, 2))
		end)

		it('hangs the excess lower matches off the last opponent', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({
				{lowerMatchIndex = 1, opponentIndex = 1},
				{lowerMatchIndex = 2, opponentIndex = 2},
				{lowerMatchIndex = 3, opponentIndex = 2},
			}, BracketUtil.autoAssignLowerEdges(3, 2))
		end)

		it('returns nothing when there are no lower matches', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({}, BracketUtil.autoAssignLowerEdges(0, 2))
		end)
	end)

	describe('computeAdvanceSpots', function()
		it('advances the winner to the upper match', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same(
				{{bg = 'up', type = 'advance', matchId = 'R02-M001'}},
				BracketUtil.computeAdvanceSpots{upperMatchId = 'R02-M001'}
			)
		end)

		it('lets winnerto and loserto override the upper match', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local spots = BracketUtil.computeAdvanceSpots{
				upperMatchId = 'R02-M001',
				winnerto = 'R02-M009',
				loserto = 'R02-M010',
			}
			assert.are_same({bg = 'up', type = 'custom', matchId = 'R02-M009'}, spots[1])
			assert.are_same({bg = 'stayup', type = 'custom', matchId = 'R02-M010'}, spots[2])
		end)

		it('marks qualification spots while keeping the target match', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local spots = BracketUtil.computeAdvanceSpots{
				upperMatchId = 'R02-M001',
				qualwin = 'true',
				quallose = 'true',
			}
			assert.are_same({bg = 'up', type = 'qualify', matchId = 'R02-M001'}, spots[1])
			assert.are_same({bg = 'stayup', type = 'qualify'}, spots[2])
		end)

		it('returns nothing for a match that goes nowhere', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({}, BracketUtil.computeAdvanceSpots{})
		end)
	end)

	describe('populateAdvanceSpots', function()
		it('does nothing for an empty bracket', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.is_true(pcall(function()
				BracketUtil.populateAdvanceSpots{matches = {}}
			end))
		end)

		it('sends the semifinal losers to the third place match', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketDatasById = {
				['R01-M001'] = {advanceSpots = {}},
				['R02-M001'] = {advanceSpots = {}, lowerMatchIds = {'R01-M001'}, thirdPlaceMatchId = 'RxMTP'},
				RxMTP = {advanceSpots = {}},
			}
			BracketUtil.populateAdvanceSpots{
				matches = {{extradata = {}, bracketData = bracketDatasById['R02-M001']}},
				matchesById = {RxMTP = {}},
				rootMatchIds = {'R02-M001'},
				bracketDatasById = bracketDatasById,
			}

			assert.are_same({bg = 'stayup', type = 'advance', matchId = 'RxMTP'},
				bracketDatasById['R01-M001'].advanceSpots[2])
		end)

		it('applies the pbg overrides from extradata', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketData = {advanceSpots = {}, lowerMatchIds = {}}
			BracketUtil.populateAdvanceSpots{
				matches = {{extradata = {pbg1 = 'down', pbg2 = 'stay'}, bracketData = bracketData}},
				matchesById = {},
				rootMatchIds = {'R01-M001'},
				bracketDatasById = {['R01-M001'] = bracketData},
			}

			assert.are_same({bg = 'down', type = 'custom'}, bracketData.advanceSpots[1])
			assert.are_same({bg = 'stay', type = 'custom'}, bracketData.advanceSpots[2])
		end)
	end)

	describe('computeRootMatchIds', function()
		it('takes the matches that have no upper match, in coordinate order', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local rootMatchIds = BracketUtil.computeRootMatchIds{
				['R01-M001'] = {upperMatchId = 'R02-M001'},
				['R02-M001'] = {coordinates = {rootIndex = 2}},
				['R02-M002'] = {coordinates = {rootIndex = 1}},
			}
			assert.are_same({'R02-M002', 'R02-M001'}, rootMatchIds)
		end)

		it('never treats a bracket reset match as a root', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_same({'R01-M001'}, BracketUtil.computeRootMatchIds{
				['R01-M001'] = {coordinates = {rootIndex = 1}},
				['abcdefghij_RxMBR'] = {coordinates = {rootIndex = 2}},
			})
		end)
	end)

	describe('backfillUpperMatchIds', function()
		it('points every lower match at the match above it', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketDatasById = {
				['R01-M001'] = {lowerMatchIds = {}},
				['R01-M002'] = {lowerMatchIds = {}},
				['R02-M001'] = {lowerMatchIds = {'R01-M001', 'R01-M002'}},
			}
			BracketUtil.backfillUpperMatchIds(bracketDatasById)

			assert.are_equal('R02-M001', bracketDatasById['R01-M001'].upperMatchId)
			assert.are_equal('R02-M001', bracketDatasById['R01-M002'].upperMatchId)
			assert.is_nil(bracketDatasById['R02-M001'].upperMatchId)
		end)
	end)

	describe('index table conversion', function()
		it('shifts only the keys ending in Index', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local coordinates = {roundIndex = 0, sectionIndex = 2, roundCount = 4, matchId = 'R01-M001'}
			local oneBased = BracketUtil.indexTableFromRecord(coordinates)

			assert.are_same({roundIndex = 1, sectionIndex = 3, roundCount = 4, matchId = 'R01-M001'}, oneBased)
			assert.are_same(coordinates, BracketUtil.indexTableToRecord(oneBased))
		end)
	end)

	describe('sectionIndexToString', function()
		it('names the first, last and middle sections', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_equal('upper', BracketUtil.sectionIndexToString(1, 3))
			assert.are_equal('mid', BracketUtil.sectionIndexToString(2, 3))
			assert.are_equal('lower', BracketUtil.sectionIndexToString(3, 3))
			-- a single section is upper, the first check wins
			assert.are_equal('upper', BracketUtil.sectionIndexToString(1, 1))
		end)
	end)

	-- match ids address a match inside its match group, so they live with the bracket half
	describe('match ids', function()
		it('splits a match id into bracket id and base match id', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local bracketId, baseMatchId = BracketUtil.splitMatchId('h5HXaqbSVP_R02-M002')
			assert.are_equal('h5HXaqbSVP', bracketId)
			assert.are_equal('R02-M002', baseMatchId)
		end)

		it('returns nothing for a match id it cannot split', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.is_nil(BracketUtil.splitMatchId('R02-M002'))
			assert.is_nil((BracketUtil.splitMatchId('')))
		end)

		it('converts between the padded and short match id forms', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_equal('R1M3', BracketUtil.matchIdToKey('R01-M003'))
			assert.are_equal('R12M345', BracketUtil.matchIdToKey('R12-M345'))
			assert.are_equal('R01-M003', BracketUtil.matchIdFromKey('R1M3'))
			assert.are_equal('R12-M345', BracketUtil.matchIdFromKey('R12M345'))
		end)

		it('leaves the reset and third place placeholders alone', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_equal('RxMBR', BracketUtil.matchIdToKey('RxMBR'))
			assert.are_equal('RxMTP', BracketUtil.matchIdToKey('RxMTP'))
			assert.are_equal('RxMBR', BracketUtil.matchIdFromKey('RxMBR'))
			assert.are_equal('RxMTP', BracketUtil.matchIdFromKey('RxMTP'))
		end)

		it('pads a matchlist key to four digits', function()
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			assert.are_equal('0003', BracketUtil.matchIdFromKey('3'))
		end)

	end)
end)
