--- Triple Comment to Enable our LLS Plugin
--[[
Tests for Module:MatchGroup/Input/Util.

`normalizeSubtype` is a tolerance shim for the input path, letting callers pass either a raw match
record or an already built match.
]]

insulate('MatchGroup/Input/Util', function()
	describe('normalizeSubtype', function()
		it('prefers the record field over the model field', function()
			local MatchGroupInputUtil = require('Module:MatchGroup/Input/Util')
			assert.are_same({'record'}, MatchGroupInputUtil.normalizeSubtype(
				{match2opponents = {'record'}, opponents = {'model'}}, 'opponent'))
			assert.are_same({'model'}, MatchGroupInputUtil.normalizeSubtype({opponents = {'model'}}, 'opponent'))
			assert.are_same({'record'}, MatchGroupInputUtil.normalizeSubtype({match2games = {'record'}}, 'map'))
		end)

		it('returns an empty list when neither field is set', function()
			local MatchGroupInputUtil = require('Module:MatchGroup/Input/Util')
			assert.are_same({}, MatchGroupInputUtil.normalizeSubtype({}, 'opponent'))
		end)

		it('rejects an unknown subtype', function()
			local MatchGroupInputUtil = require('Module:MatchGroup/Input/Util')
			---@diagnostic disable-next-line: param-type-mismatch
			assert.has_error(function() MatchGroupInputUtil.normalizeSubtype({}, 'player') end, 'Invalid subtype: player')
		end)
	end)

	describe('getStandaloneId', function()
		it('builds a standalone id, and nothing without both parts', function()
			local MatchGroupInputUtil = require('Module:MatchGroup/Input/Util')
			assert.are_equal('MATCH_abcdefghij_R01-M001',
				MatchGroupInputUtil.getStandaloneId('abcdefghij', 'R01-M001'))
			assert.is_nil(MatchGroupInputUtil.getStandaloneId('abcdefghij', nil))
			assert.is_nil(MatchGroupInputUtil.getStandaloneId(nil, 'R01-M001'))
		end)
	end)
end)
