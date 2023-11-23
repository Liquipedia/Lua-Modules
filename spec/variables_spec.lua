--- Triple Comment to Enable our LLS Plugin
describe('Variables', function()
	local Variables = require('Module:Variables')

	describe('varDefine', function()
		it('verify', function()
			assert.are_equal('', Variables.varDefine('test', 'foo'))
			assert.are_equal('foo', Variables.varDefault('test'))

			assert.are_equal('bar', Variables.varDefineEcho('test', 'bar'))
			assert.are_equal('bar', Variables.varDefault('test'))

			assert.are_equal('', Variables.varDefine('test', 3))
			assert.are_equal('3', Variables.varDefault('test'))

			assert.are_equal('', Variables.varDefine('test'))
			assert.is_nil(Variables.varDefault('test'))
		end)
	end)

	describe('varDefault', function()
		it('verify', function()
			Variables.varDefine('test', 'foo')
			assert.are_equal('foo', Variables.varDefault('test'))
			assert.is_nil(Variables.varDefault('bar'))
			assert.are_equal('baz', Variables.varDefault('bar', 'baz'))
		end)
	end)

	describe('VarDefaultMulti', function()
		it('verify', function()
			Variables.varDefine('baz', 'hello world')
			assert.are_equal('hello world', Variables.varDefaultMulti('foo', 'bar', 'baz'))
			assert.are_equal('banana', Variables.varDefaultMulti('foo', 'bar', 'banana'))
		end)
	end)
end)
