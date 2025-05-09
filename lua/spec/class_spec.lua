--- Triple Comment to Enable our LLS Plugin
describe('class', function()
	local Class = require('Module:Class')

	local Animal = Class.new()

	function Animal:type()
		return 'Animal'
	end

	function Animal:size()
		error('abstract')
	end

	function Animal:numLegs()
		error('abstract')
	end

	local Cat = Class.new(Animal, function (self, size)
		self.size = size
	end)

	function Cat:type()
		return 'Cat'
	end

	function Cat:size()
		return self.size
	end

	function Cat:numLegs()
		return 4
	end

	describe('base', function()
		it('base class', function ()
			local a1 = Animal()
			assert.equal('Animal', a1:type())
			assert.error(a1:numLegs())
			assert.error(a1:size())
		end)
	end)

	describe('subclass', function()
		it('base class', function ()
			local c1 = Cat(5)
			assert.equal('Cat', c1:type())
			assert.equal(4, c1:numLegs())
			assert.equal(5, c1:size())
		end)
	end)
end)
