--- Triple Comment to Enable our LLS Plugin

--- The fixtures below name only the fields each test is about, rather than whole records.
---@diagnostic disable: missing-fields

--[[
Tests for Module:MatchGroup/Util: fetching match records and assembling them into match groups.

It also re-exports the match and bracket models, so there is a test that every re-export points at
its implementation.
]]

--- Casts a partial record to a match2 record, so a test only has to name the fields it cares about.
---@param record table
---@return match2
local function matchRecord(record)
	return record
end

insulate('MatchGroup/Util', function()
	describe('makeMatchGroup', function()
		---@param bracketData table
		---@param matchId string
		---@return table
		local function record(matchId, bracketData)
			return matchRecord{
				match2id = matchId,
				date = '2022-01-05',
				mode = 'team',
				match2bracketdata = bracketData,
				match2opponents = {{name = 'A', match2players = {}}, {name = 'B', match2players = {}}},
				match2games = {},
			}
		end

		it('defaults to a matchlist when there are no records', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local matchGroup = MatchGroupUtil.makeMatchGroup{}
			assert.are_equal('matchlist', matchGroup.type)
			assert.are_same({}, matchGroup.matches)
		end)

		it('builds a matchlist indexed by match id', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local matchGroup = MatchGroupUtil.makeMatchGroup{
				record('abc_0001', {type = 'matchlist', header = 'Round 1'}),
				record('abc_0002', {type = 'matchlist'}),
			}

			assert.are_equal('matchlist', matchGroup.type)
			assert.are_equal(2, #matchGroup.matches)
			assert.are_equal('abc_0001', matchGroup.matchesById['abc_0001'].matchId)
			assert.are_equal('Round 1', matchGroup.bracketDatasById['abc_0001'].header)
		end)

		it('builds a bracket with root matches and coordinates', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local matchGroup = MatchGroupUtil.makeMatchGroup{
				record('abc_R01-M001', {type = 'bracket'}),
				record('abc_R01-M002', {type = 'bracket'}),
				record('abc_R02-M001', {type = 'bracket', header = 'Final',
					lowerMatchIds = {'abc_R01-M001', 'abc_R01-M002'}}),
			}

			assert.are_equal('bracket', matchGroup.type)
			assert.are_same({'abc_R02-M001'}, matchGroup.rootMatchIds)
			-- the records carried no coordinates, so they were backfilled
			assert.is_truthy(matchGroup.coordinatesByMatchId['abc_R02-M001'])
			assert.are_equal('abc_R02-M001', matchGroup.bracketDatasById['abc_R01-M001'].upperMatchId)
		end)

		it('errors on a bracket whose root match has no header', function()
			-- computing the sections opens the first section on the first match that carries a header, so a
			-- headerless root leaves nothing to put it in
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			assert.has_error(function()
				MatchGroupUtil.makeMatchGroup{record('abc_R01-M001', {type = 'bracket'})}
			end)
		end)

		it('keeps the coordinates that the records already carry', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local matchGroup = MatchGroupUtil.makeMatchGroup{
				record('abc_R01-M001', {
					type = 'bracket',
					header = 'Final',
					coordinates = {roundIndex = 0, sectionIndex = 0, roundCount = 1, sectionCount = 1,
						depth = 0, depthCount = 1, matchIndexInRound = 0, rootIndex = 0,
						semanticDepth = 1, semanticRoundIndex = 0},
				}),
			}

			assert.are_equal(1, matchGroup.coordinatesByMatchId['abc_R01-M001'].roundIndex)
			assert.is_truthy(matchGroup.rounds)
			assert.is_truthy(matchGroup.sections)
		end)

		it('rejects an unknown match group type', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			assert.has_error(
				function() MatchGroupUtil.makeMatchGroup{record('abc_0001', {type = 'ladder'})} end,
				'Invalid match2bracketdata.type: ladder. Expected matchlist or bracket.'
			)
		end)
	end)

	describe('fetching', function()
		it('reads match ids off the query result', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local queryStub = stub(mw.ext.LiquipediaDB, 'lpdb', function()
				return {{match2id = 'a'}, {match2id = 'b'}}
			end)
			local matchIds = MatchGroupUtil.fetchMatchIds{conditions = '[[x::y]]', limit = 5, order = 'date asc'}
			queryStub:revert()

			assert.are_same({'a', 'b'}, matchIds)
			assert.stub(queryStub).was.called_with('match2', {
				conditions = '[[x::y]]',
				limit = 5,
				order = 'date asc',
				query = 'match2id',
			})
		end)

		it('defaults the match id query limit to 1000', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local params
			local queryStub = stub(mw.ext.LiquipediaDB, 'lpdb', function(_, queryParams)
				params = queryParams
				return {}
			end)
			MatchGroupUtil.fetchMatchIds{conditions = '[[x::y]]'}
			queryStub:revert()
			assert.are_equal(1000, params.limit)
		end)

		it('reads the records of a bracket from lpdb', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local queryStub = stub(mw.ext.LiquipediaDB, 'lpdb', function() return {{match2id = 'a'}} end)
			local records = MatchGroupUtil.fetchMatchRecords('abcdefghij')
			queryStub:revert()

			assert.are_same({{match2id = 'a'}}, records)
			assert.stub(queryStub).was.called_with('match2', {
				conditions = '([[namespace::0]] or [[namespace::>0]]) AND [[match2bracketid::abcdefghij]]',
				order = 'match2id ASC',
				limit = 5000,
			})
		end)

		it('returns the finals together with its bracket reset match', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local Variables = require('Module:Variables')
			local Json = require('Module:Json')

			local function record(matchId, bracketData)
				return {
					match2id = matchId,
					date = '2022-01-05',
					mode = 'team',
					match2bracketdata = bracketData,
					match2opponents = {{name = 'A', match2players = {}}, {name = 'B', match2players = {}}},
					match2games = {},
				}
			end

			Variables.varDefine('match2bracket_resetbracket', Json.stringify{
				record('resetbracket_R01-M001', {type = 'bracket', header = 'Final',
					bracketreset = 'resetbracket_RxMBR'}),
				record('resetbracket_RxMBR', {type = 'bracket'}),
			})

			local finals, resetMatch = MatchGroupUtil.fetchMatchForBracketDisplay(
				'resetbracket', 'resetbracket_R01-M001')

			assert.is_truthy(finals)
			assert.is_truthy(resetMatch)
			assert.are_equal('resetbracket_R01-M001', finals.matchId)
			assert.are_equal('resetbracket_RxMBR', assert(resetMatch).matchId)
		end)

		it('prefers the page variable over lpdb', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local Variables = require('Module:Variables')
			local queryStub = stub(mw.ext.LiquipediaDB, 'lpdb', {})
			Variables.varDefine('match2bracket_abcdefghij', '[{"match2id":"cached"}]')
			local records = MatchGroupUtil.fetchMatchRecords('abcdefghij')
			queryStub:revert()

			assert.are_same({{match2id = 'cached'}}, records)
			assert.spy(queryStub).was.called(0)
		end)
	end)
	describe('re-exports', function()
		it('points every match and bracket model member at its implementation', function()
			local MatchGroupUtil = require('Module:MatchGroup/Util')
			local MatchUtil = require('Module:MatchGroup/Util/Match')
			local BracketUtil = require('Module:MatchGroup/Util/Bracket')
			local Types = require('Module:MatchGroup/Util/Types')

			assert.are_equal(Types, MatchGroupUtil.types)
			for _, model in ipairs({MatchUtil, BracketUtil}) do
				for name, implementation in pairs(model) do
					assert.are_equal(implementation, MatchGroupUtil[name],
						'MatchGroupUtil.' .. name .. ' does not re-export its implementation')
				end
			end
		end)
	end)
end)
