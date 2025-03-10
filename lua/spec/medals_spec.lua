--- Triple Comment to Enable our LLS Plugin
local Medals = require('Module:Medals')

describe('Medals.display', function()
	it('should return nil when args is nil', function()
		local result = Medals.display(nil)
		assert.is_nil(result)
	end)

	it('should return correct HTML when args.medal is a valid string', function()
		local args = {medal = '1'}
		local result = tostring(Medals.display(args))
		assert.are.equal('<span title="First Place">[[File:Gold.png|link=|alt=First Place]]</span>', result)
	end)

	it('should return correct HTML when args.medal is a valid integer', function()
		local args = {medal = 1}
		local result = tostring(Medals.display(args))
		assert.are.equal('<span title="First Place">[[File:Gold.png|link=|alt=First Place]]</span>', result)
	end)

	it('should return nil when args.medal is invalid', function()
		local args = {medal = 'invalid'}
		local result = Medals.display(args)
		assert.is_nil(result)
	end)

	it('should use link when provided', function()
		local args = {medal = 1, link = 'somepage'}
		local result = tostring(Medals.display(args))
		assert.are.equal('<span title="First Place">[[File:Gold.png|link=somepage|alt=First Place]]</span>', result)
	end)
end)

describe('Medals.getData', function()
	it('should return correct data when input is a valid string', function()
		local result = Medals.getData('1')
		assert.are.same({title = 'First Place', file = 'Gold.png'}, result)
	end)

	it('should return correct data when input is a valid integer', function()
		local result = Medals.getData(1)
		assert.are.same({title = 'First Place', file = 'Gold.png'}, result)
	end)

	it('should return nil when input is invalid', function()
		local result = Medals.getData('invalid')
		assert.is_nil(result)
	end)
end)
