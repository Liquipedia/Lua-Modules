--- Triple Comment to Enable our LLS Plugin
describe('class', function()
	local Class = require('Module:Class')

	local Animal = Class.new()

	function Animal:type()
		return 'Animal'
	end

	Animal.__tostring = Animal.type

	function Animal:size()
		error('abstract')
	end

	function Animal:numLegs()
		error('abstract')
	end

	local Cat = Class.new(Animal, function (self, size)
		self._size = size
	end)

	function Cat:type()
		return 'Cat'
	end

	function Cat:size()
		return self._size
	end

	function Cat:numLegs()
		return 4
	end

	describe('class operations', function()
		it('base class', function ()
			local a1 = Animal()
			assert.equal('Animal', a1:type())
			assert.error(function() return a1:numLegs() end)
			assert.error(function() return a1:size() end)
		end)

		it('subclass', function ()
			local c1 = Cat(5)
			assert.equal('Cat', c1:type())
			assert.equal(4, c1:numLegs())
			assert.equal(5, c1:size())
		end)
	end)

	describe('super', function()
		it('access super methods', function ()
			local c1 = Cat(5)

			assert.equal('Animal', c1:super():type())
			assert.error(function() return c1:super():numLegs() end)
		end)

		it('access instance value from super', function ()
			local c1 = Cat(5)

			assert.equal(5, c1:super()._size)
		end)
	end)

	describe('instanceOf', function()
		it('with same class', function ()
			local c1 = Cat(5)

			assert.is_true(Class.instanceOf(c1, Cat))
		end)

		it('in same hierarchy', function ()
			local c1 = Cat(5)
			assert.is_true(Class.instanceOf(c1, Animal))

			local a1 = Animal()
			assert.is_false(Class.instanceOf(a1, Cat))
		end)

		it('with super', function ()
			local c1 = Cat(5)
			assert.is_true(Class.instanceOf(c1:super(), Animal))
			assert.is_false(Class.instanceOf(c1:super(), Cat))
		end)
	end)
end)
