describe('logic', function()
	local Logic, Table

	setup(function()
		Logic = require('Module:Logic')
		Table = require('Module:Table')
	end)

	teardown(function()
		Logic = nil
		Table = nil
	end)

	describe('EmptyOr', function()
		it('check', function()
			assert.are_equal(1, Logic.emptyOr(1, 2, 3))
			assert.are_equal(1, Logic.emptyOr(1, 2))
			assert.are_equal(1, Logic.emptyOr(1, nil, 3))
			assert.are_equal(1, Logic.emptyOr(1, '', 3))
			assert.are_equal(1, Logic.emptyOr(1))
			assert.are_equal(2, Logic.emptyOr(nil, 2, 3))
			assert.are_equal(2, Logic.emptyOr('', 2, 3))
			assert.are_equal(2, Logic.emptyOr(nil, 2))
			assert.are_equal(2, Logic.emptyOr('', 2))
			assert.are_equal(3, Logic.emptyOr(nil, nil, 3))
			assert.are_equal(3, Logic.emptyOr({}, '', 3))
			assert.is_nil(Logic.emptyOr())
		end)
	end)

	describe('NilOr', function()
		it('check', function()
			assert.are_equal(1, Logic.nilOr(1, 2, 3))
			assert.are_equal(1, Logic.nilOr(1, 2))
			assert.are_equal(1, Logic.nilOr(1, nil, 3))
			assert.are_equal(1, Logic.nilOr(1, '', 3))
			assert.are_equal(1, Logic.nilOr(1))
			assert.are_equal(2, Logic.nilOr(nil, 2, 3))
			assert.are_equal('', Logic.nilOr('', 2, 3))
			assert.are_equal(2, Logic.nilOr(nil, 2))
			assert.are_equal('', Logic.nilOr('', 2))
			assert.are_equal(3, Logic.nilOr(nil, nil, 3))
			assert.are_same({}, Logic.nilOr({}, '', 3))
			assert.is_nil(Logic.nilOr())
			assert.are_equal(5, Logic.nilOr(nil, nil, nil, nil, 5))
		end)
	end)

	describe('IsEmpty', function()
		it('check', function()
			assert.is_true(Logic.isEmpty({}))
			assert.is_true(Logic.isEmpty())
			assert.is_true(Logic.isEmpty(''))
			assert.is_false(Logic.isEmpty({''}))
			assert.is_false(Logic.isEmpty({'string'}))
			assert.is_false(Logic.isEmpty({{}}))
			assert.is_false(Logic.isEmpty(1))
			assert.is_false(Logic.isEmpty('string'))
		end)
	end)

	describe('IsDeepEmpty', function()
		it('check', function()
			assert.is_true(Logic.isDeepEmpty({}))
			assert.is_true(Logic.isDeepEmpty())
			assert.is_true(Logic.isDeepEmpty(''))
			assert.is_true(Logic.isDeepEmpty({''}))
			assert.is_false(Logic.isDeepEmpty({'string'}))
			assert.is_true(Logic.isDeepEmpty({{}}))
			assert.is_false(Logic.isDeepEmpty(1))
			assert.is_false(Logic.isDeepEmpty('string'))
		end)
	end)

	describe('ReadBool', function()
		it('check', function()
			assert.is_true(Logic.readBool(1))
			assert.is_true(Logic.readBool('true'))
			assert.is_true(Logic.readBool(true))
			assert.is_true(Logic.readBool('t'))
			assert.is_true(Logic.readBool('y'))
			assert.is_true(Logic.readBool('yes'))
			assert.is_true(Logic.readBool('1'))
			assert.is_false(Logic.readBool(0))
			assert.is_false(Logic.readBool(false))
			assert.is_false(Logic.readBool('false'))
			assert.is_false(Logic.readBool('f'))
			assert.is_false(Logic.readBool('0'))
			assert.is_false(Logic.readBool('no'))
			assert.is_false(Logic.readBool('n'))
			assert.is_false(Logic.readBool('someBs'))
			assert.is_false(Logic.readBool())
			---intended bad value
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_false(Logic.readBool{})
		end)
	end)

	describe('ReadBoolOrNil', function()
		it('check', function()
			assert.is_true(Logic.readBoolOrNil(1))
			assert.is_true(Logic.readBoolOrNil('true'))
			assert.is_true(Logic.readBoolOrNil(true))
			assert.is_true(Logic.readBoolOrNil('t'))
			assert.is_true(Logic.readBoolOrNil('y'))
			assert.is_true(Logic.readBoolOrNil('yes'))
			assert.is_true(Logic.readBoolOrNil('1'))
			assert.is_false(Logic.readBoolOrNil(0))
			assert.is_false(Logic.readBoolOrNil(false))
			assert.is_false(Logic.readBoolOrNil('false'))
			assert.is_false(Logic.readBoolOrNil('f'))
			assert.is_false(Logic.readBoolOrNil('0'))
			assert.is_false(Logic.readBoolOrNil('no'))
			assert.is_false(Logic.readBoolOrNil('n'))
			assert.is_nil(Logic.readBoolOrNil('someBs'))
			assert.is_nil(Logic.readBoolOrNil())
			---intended bad value
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_nil(Logic.readBoolOrNil{})
		end)
	end)

	describe('NilThrows', function()
		it('check', function()
			assert.are_equal('someVal', Logic.nilThrows('someVal'))
			assert.are_equal('', Logic.nilThrows(''))
			assert.are_equal(1, Logic.nilThrows(1))
			assert.are_same({'someVal'}, Logic.nilThrows({'someVal'}))
			assert.are_same({}, Logic.nilThrows({}))
			assert.error(function() return Logic.nilThrows() end)
		end)
	end)

	describe('TryCatch', function()
		it('check', function()
			local errorCaught = false
			local catch = function(errorMessage) errorCaught = true end

			assert.is_nil(Logic.tryCatch(function() error() end, catch))
			assert.is_true(errorCaught)
			errorCaught = false

			assert.is_nil(Logic.tryCatch(function() error('some error') end, catch))
			assert.is_true(errorCaught)
			errorCaught = false

			assert.is_nil(Logic.tryCatch(function() assert(false, 'some failed assert') end, catch))
			assert.is_true(errorCaught)
			errorCaught = false

			assert.are_equal('someVal', Logic.tryCatch(function() return 'someVal' end, catch))
			assert.is_false(errorCaught)
		end)
	end)

	describe('IsNumeric', function()
		it('check', function()
			assert.is_true(Logic.isNumeric(1.5))
			assert.is_true(Logic.isNumeric('1.5'))
			assert.is_true(Logic.isNumeric('4.57e-3'))
			assert.is_true(Logic.isNumeric(4.57e-3))
			assert.is_true(Logic.isNumeric(0.3e12))
			assert.is_true(Logic.isNumeric('0.3e12'))
			assert.is_true(Logic.isNumeric(5e+20))
			assert.is_true(Logic.isNumeric('5e+20'))
			assert.is_false(Logic.isNumeric('1+2'))
			assert.is_false(Logic.isNumeric())
			assert.is_false(Logic.isNumeric('string'))
			---intended bad value
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_false(Logic.isNumeric{})
			---intended bad value
			---@diagnostic disable-next-line: param-type-mismatch
			assert.is_false(Logic.isNumeric{just = 'a table'})
		end)
	end)

	describe('deepEquals', function()
		it('check', function()
			assert.is_true(Logic.deepEquals(1, 1))
			assert.is_false(Logic.deepEquals(1, 2))
			assert.is_true(Logic.deepEquals('a', 'a'))
			assert.is_false(Logic.deepEquals('a', 'b'))

			local tbl1 = {1, 2, {3, 4, {a = 'b'}}}
			local tbl2 = {1, 2, {3, 4, {a = 'c'}}}
			local tbl3 = {1, 2, {3, 4, {a = 'b'}, 6}}
			assert.is_true(Logic.deepEquals(tbl1, tbl1))
			assert.is_true(Logic.deepEquals(tbl1, Table.deepCopy(tbl1)))
			assert.is_false(Logic.deepEquals(tbl1, tbl2))
			assert.is_false(Logic.deepEquals(tbl1, tbl3))
		end)
	end)

	--currently not testing:
	---try - just uses `Module:ResultOrError`
	---tryOrElseLog - uses `.try` plus `:catch` and `:get`
	---wrapTryOrLog - basically tryOrElseLog
end)
