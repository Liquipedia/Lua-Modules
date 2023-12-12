--- Triple Comment to Enable our LLS Plugin
describe('Table', function()
	local Data = mw.loadData('Module:Flags/MasterData')
	local Logic = require('Module:Logic')
	local Table = require('Module:Table')

	describe('size', function()
		it('verify', function()
			assert.are_equal(3, Table.size{1, 3, 6})
			assert.are_equal(1, Table.size{1})
			assert.are_equal(0, Table.size{})
		end)
	end)

	describe('is empty', function()
		it('verify', function()
			assert.is_false(Table.isEmpty{1, 3, 6})
			assert.is_false(Table.isEmpty{1})
			assert.is_true(Table.isEmpty{})
			assert.is_true(Table.isEmpty())
			assert.is_false(Table.isEmpty(Data))
		end)
	end)

	describe('is not empty', function()
		it('verify', function()
			assert.is_true(Table.isNotEmpty{1, 3, 6})
			assert.is_true(Table.isNotEmpty{1})
			assert.is_false(Table.isNotEmpty{})
			assert.is_false(Table.isNotEmpty())
			assert.is_true(Table.isNotEmpty(Data))
		end)
	end)

	describe('copy', function()
		it('verify', function()
			local a, b, c = {1, 2, 3}, {}, {a = {}}
			assert.are_same(a, Table.copy(a))
			assert.is_false(Table.copy(b) == b)
			assert.is_true(Table.copy(c).a == c.a)
		end)
	end)

	describe('deep', function()
		it('verify', function()
			local a, b, c = {1, 2, 3}, {}, {a = {}}
			assert.is_true(Table.deepEquals(Table.deepCopy(a), a))
			assert.is_true(Table.deepEquals(Table.deepCopy(b), b))
			assert.is_false(Table.deepEquals(Table.deepCopy(b), a))
			assert.is_false(Table.deepCopy(c).a == c.a)
		end)
	end)

	describe('merge', function()
		it('verify', function()
			local a, b, c = {1, 2, 3}, {c = 5}, {a = 3}
			local d = Table.merge(a, b, c)
			local e = Table.mergeInto(a, b, c)
			assert.is_false(a == d)
			assert.is_true(a == e)
			assert.are_same({1, 2, 3, c = 5, a = 3}, d)
			assert.are_same({1, 2, 3, c = 5, a = 3}, e)
		end)
	end)

	describe('deep merge', function()
		it('verify',
			function()
				assert.are_same({a = {x = 3, y = 5}}, Table.deepMergeInto({a = {x = 3, y = 4}}, {a = {y = 5}}))
			end)
	end)

	describe('map', function()
		it('verify', function()
			local a = {a = 3, b = 4, c = 5}
			assert.are_same({[6] = 'a', [8] = 'b', [10] = 'c'}, Table.map(a, function(k, v)
				return 2 * v, k
			end))
		end)
	end)

	describe('map Arguments', function()
		it('verify', function()
			local args = {a1a = 1, a3a = 3, a4a = 4, 2, 5}

			local function indexFromKey(key)
				local index = key:match('^a(%d+)a$')
				if index then
					return tonumber(index)
				else
					return nil
				end
			end

			local function mapFunction(key)
				return args[key] * 2
			end

			assert.are_same({2, 4, 6, 8, 10}, Table.mapArguments(args, indexFromKey, mapFunction))
			assert.are_same({2, [3] = 6, [4] = 8}, Table.mapArguments(args, indexFromKey, mapFunction, true))
		end)
	end)

	describe('map values', function()
		it('verify', function()
			local a = {1, 2, 3}
			assert.are_same({2, 4, 6}, Table.mapValues(a, function(x)
				return 2 * x
			end
			))
		end)
	end)

	describe('all contains', function()
		it('verify', function()
			local a = {1, 2, 3}
			assert.is_true(Table.all(a, function(key, value)
				return key == value
			end))
			assert.is_false(Table.all(a, function(key, value)
				return value < 3
			end))
		end)
	end)

	describe('any contains', function()
		it('verify', function()
			local a = {1, 2, 3}
			assert.is_false(Table.any(a, function(key, value)
				return type(value) == 'string'
			end))
			assert.is_true(Table.any(a, function(key, value)
				return value < 3
			end))
		end)
	end)

	describe('extract', function()
		it('verify', function()
			local a = {1, 2, 3}
			local b = Table.extract(a, 1)
			assert.are_same({[2] = 2, [3] = 3}, a)
			assert.are_equal(1, b)
		end)
	end)

	describe('includes', function()
		it('verify', function()
			local a = {'testValue', 'testValue2', 'testValue3'}
			local b = {key1 = 'testValue', key2 = 'testValue2', 'testValue3'}
			assert.is_true(Table.includes(a, 'testValue'))
			assert.is_true(Table.includes(b, 'testValue'))
			assert.is_true(Table.includes(b, 'testValue3'))
			assert.is_false(Table.includes(a, 'testValue4'))
			assert.is_false(Table.includes(b, 'testValue4'))

			assert.is_true(Table.includes(a, 'testValue', false))
			assert.is_true(Table.includes(b, 'testValue', false))
			assert.is_true(Table.includes({'^estValue3$'}, '^estValue3$', false))
			assert.is_false(Table.includes(b, 'estValue', false))

			assert.is_true(Table.includes(a, 'testValue', true))
			assert.is_true(Table.includes(b, 'testValue', true))
			assert.is_true(Table.includes(b, 'testValue3', true))
			assert.is_true(Table.includes(b, 'estValue3', true))
			assert.is_true(Table.includes(b, 'testValue%d', true))
			assert.is_true(Table.includes(b, '^testValue%d$', true))
			assert.is_false(Table.includes(b, '^estValue3$', true))
			assert.is_false(Table.includes({'^estValue3$'}, '^estValue3$', true))
		end)
	end)

	describe('filter by key', function()
		it('verify', function()
			local a = {a1a = 1, a3a = 3, a4a = 4, 2, 5, b1b = 'ttt', c1c = 'ddd'}

			local function predicate1(key)
				return not Logic.isEmpty(string.find(key, '^%l(%d+)%l$'))
			end

			local function predicate2(key, value)
				return Logic.isNumeric(value) and not Logic.isEmpty(string.find(key, '^%l(%d+)%l$'))
			end

			assert.are_same({a1a = 1, a3a = 3, a4a = 4, b1b = 'ttt', c1c = 'ddd'}, Table.filterByKey(a, predicate1))
			assert.are_same({a1a = 1, a3a = 3, a4a = 4,}, Table.filterByKey(a, predicate2))
		end)
	end)

	describe('pairs by prefix', function()
		it('verify', function()
			local args = {
				p = 'a',
				plink = 'b',
				f1 = 'a2',
				f1link = 'b2',
				p2 = 'c',
				p2link = 'd',
				p3 = 'e',
				p3link = 'f',
				foo = {},
				p10 = {},
			}

			local cnt = 0
			for prefix in Table.iter.pairsByPrefix(args, 'p', {requireIndex = false}) do
				cnt = cnt + 1
				assert.is_not_nil(args[prefix])
				assert.is_not_nil(args[prefix .. 'link'])
			end
			assert.are_equal(3, cnt)

			cnt = 0
			for prefix in Table.iter.pairsByPrefix(args, 'p') do
				cnt = cnt + 1
				assert.is_not_nil(args[prefix])
				assert.is_not_nil(args[prefix .. 'link'])
			end
			assert.are_equal(0, cnt)

			cnt = 0
			for prefix in Table.iter.pairsByPrefix(args, {'p', 'f'}) do
				cnt = cnt + 1
				assert.is_not_nil(args[prefix])
				assert.is_not_nil(args[prefix .. 'link'])
				if cnt == 1 then
					assert.are_equal('f1', prefix)
				else
					assert.are_equal('p' .. cnt, prefix)
				end
			end
			assert.are_equal(3, cnt)

			args.p1, args.p1link = args.p, args.plink
			args.p, args.plink = nil, nil

			cnt = 0
			for prefix in Table.iter.pairsByPrefix(args, 'p', {requireIndex = false}) do
				cnt = cnt + 1
				assert.is_not_nil(args[prefix])
				assert.is_not_nil(args[prefix .. 'link'])
			end
			assert.are_equal(3, cnt)

			cnt = 0
			for prefix in Table.iter.pairsByPrefix(args, 'p') do
				cnt = cnt + 1
				assert.is_not_nil(args[prefix])
				assert.is_not_nil(args[prefix .. 'link'])
			end
			assert.are_equal(3, cnt)
		end)
	end)
end)
