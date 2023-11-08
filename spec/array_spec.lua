--- Triple Comment to Enable our LLS Plugin
describe('array', function()
	local Array = require('Module:Array')
	local Table = require('Module:Table')

	describe('isArray', function()
		it('Empty table is array', function()
			assert.is_true(Array.isArray{})
		end)
		it('Arrays are array', function()
			assert.is_true(Array.isArray{5, 2, 3})
		end)
		it('Tables are array', function()
			assert.is_false(Array.isArray{a = 1, [3] = 2, c = 3})
			assert.is_false(Array.isArray{5, 2, c = 3})
		end)
	end)

	describe('Copy', function()
		it('check', function()
			local a, b, c = {1, 2, 3}, {}, {{5}}
			assert.are_same(a, Array.copy(a))
			assert.is_false(Array.copy(b) == b)
			assert.is_true(Array.copy(c)[1] == c[1])
		end)
	end)

	describe('Sub', function()
		it('check', function()
			local a = {3, 5, 7, 11}
			assert.are_same({5, 7, 11}, Array.sub(a, 2))
			assert.are_same({5, 7}, Array.sub(a, 2, 3))
			assert.are_same({7, 11}, Array.sub(a, -2, -1))
		end)
	end)

	describe('Map', function()
		it('check', function()
			local a = {1, 2, 3}
			assert.are_same({2, 4, 6}, Array.map(a, function(x)
				return 2 * x
			end))
		end)
	end)

	describe('Filter', function()
		it('check', function()
			local a = {1, 2, 3}
			assert.are_same({1, 3}, Array.filter(a, function(x)
				return x % 2 == 1
			end
			))
		end)
	end)

	describe('Flatten', function()
		it('check', function()
			local a = {1, 2, 3, {5, 3}, {6, 4}}
			assert.are_same({1, 2, 3, 5, 3, 6, 4}, Array.flatten(a))
		end)
	end)

	describe('All', function()
		it('check', function()
			local a = {1, 2, 3}
			assert.is_true(Array.all(a, function(value)
				return type(value) == 'number'
			end))
			assert.is_false(Array.all(a, function(value)
				return value < 3
			end))
		end)
	end)

	describe('Any', function()
		it('check', function()
			local a = {1, 2, 3}
			assert.is_false(Array.any(a, function(value)
				return type(value) == 'string'
			end))
			assert.is_true(Array.any(a, function(value)
				return value < 3
			end))
		end)
	end)

	describe('Find', function()
		it('check', function()
			local a = {4, 6, 9}
			local b = Array.find(a, function(value, index)
				return index == 2
			end)
			local c = Array.find(a, function(value, index)
				return index == -1
			end)
			assert.are_equal(6, b)
			assert.are_equal(nil, c)
		end)
	end)

	describe('Revese', function()
		it('check', function()
			local a = {4, 6, 9}
			assert.are_same({9, 6, 4}, Array.reverse(a))
		end)
	end)

	describe('Append', function()
		it('check', function()
			local a = {2, 3}
			assert.are_same({2, 3, 5, 7, 11}, Array.append(a, 5, 7, 11))
			assert.are_same({2, 3}, a)
		end)
	end)

	describe('AppendWith', function()
		it('check', function()
			local a = {2, 3}
			assert.are_same({2, 3, 5, 7, 11}, Array.appendWith(a, 5, 7, 11))
			assert.are_same({2, 3, 5, 7, 11}, a)
		end)
	end)

	describe('Extend', function()
		it('check', function()
			local a, b, c = {2, 3}, {5, 7, 11}, {13}
			assert.are_same({2, 3, 5, 7, 11, 13}, Array.extend(a, b, c))
			assert.are_same({2, 3}, a)
		end)
	end)

	describe('ExtendWith', function()
		it('check', function()
			local a, b, c = {2, 3}, {5, 7, 11}, {13}
			assert.are_same({2, 3, 5, 7, 11, 13}, Array.extendWith(a, b, c))
			assert.are_same({2, 3, 5, 7, 11, 13}, a)
		end)
	end)

	describe('MapIndexes', function()
		it('check', function()
			local a = {p1 = 'Abc', p2 = 'cd', p3 = 'cake'}
			assert.are_same({'p1Abc', 'p2cd'}, Array.mapIndexes(function(x)
				local prefix = 'p' .. x
				return a[prefix] ~= 'cake' and (prefix .. a[prefix]) or nil
			end))
		end)
	end)

	describe('Range', function()
		it('check', function()
			assert.are_same({1, 2, 3}, Array.range(1, 3))
			assert.are_same({2, 3}, Array.range(2, 3))
		end)
	end)

	describe('ForEach', function()
		it('check', function()
			local a = {}
			Array.forEach(Array.range(1, 3), function(x)
				table.insert(a, 1, x)
			end)
			assert.are_same({3, 2, 1}, a)
		end)
	end)

	describe('Reduce', function()
		it('check', function()
			local function pow(x, y) return x ^ y end
			assert.are_same(32768, Array.reduce({2, 3, 5}, pow))
			assert.are_same(1, Array.reduce({2, 3, 5}, pow, 1))
		end)
	end)

	describe('ExtractValues', function()
		it('check', function()
			local a = {i = 1, j = 2, k = 3, z = 0}

			local customOrder1 = function(_, key1, key2) return key1 > key2 end
			local customOrder2 = function(tbl, key1, key2) return tbl[key1] < tbl[key2] end

			assert.are_same({1, 2, 3, 0}, Array.extractValues(a, Table.iter.spairs))
			assert.are_same({0, 3, 2, 1}, Array.extractValues(a, Table.iter.spairs, customOrder1))
			assert.are_same({0, 1, 2, 3}, Array.extractValues(a, Table.iter.spairs, customOrder2))

			local extractedArray = Array.extractValues(a)
			table.sort(extractedArray)
			assert.are_same({0, 1, 2, 3}, extractedArray)
		end)
	end)

	describe('ExtractKeys', function()
		it('check', function()
			local a = {k = 3, i = 1, z = 0, j = 2}

			local customOrder1 = function(_, key1, key2) return key1 > key2 end
			local customOrder2 = function(tbl, key1, key2) return tbl[key1] < tbl[key2] end

			assert.are_same({'i', 'j', 'k', 'z'}, Array.extractKeys(a, Table.iter.spairs))
			assert.are_same({'z', 'k', 'j', 'i'}, Array.extractKeys(a, Table.iter.spairs, customOrder1))
			assert.are_same({'z', 'i', 'j', 'k'}, Array.extractKeys(a, Table.iter.spairs, customOrder2))

			local extractedKeys = Array.extractKeys(a)
			table.sort(extractedKeys)
			assert.are_same({'i', 'j', 'k', 'z'}, extractedKeys)
		end)
	end)
end)
