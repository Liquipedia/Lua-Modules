--- Triple Comment to Enable our LLS Plugin
describe("FeatureFlag", function()
	local FeatureFlag = require('Module:FeatureFlag')
	before_each(function()
		FeatureFlag.clearCache()
	end)

	describe("get", function()
		it("should return true for an enabled flag", function()
			mw.ext.VariablesLua.vardefine('feature_dev', '1')
			assert.is_true(FeatureFlag.get('dev'))
		end)

		it("should return false for a disabled flag", function()
			mw.ext.VariablesLua.vardefine('feature_dev', '0')
			assert.is_false(FeatureFlag.get('dev'))
		end)

		it("should string for a string flag", function()
			mw.ext.VariablesLua.vardefine('feature_dev', 'foobar')
			assert.are_equal('foobar', FeatureFlag.get('dev'))
		end)

		it("should return default value for a flag not set", function()
			mw.ext.VariablesLua.vardefine('feature_dev', '')
			assert.are_equal(FeatureFlag.getConfig('dev').defaultValue, FeatureFlag.get('dev'))
		end)
	end)

	describe("set", function()
		it("should set a flag to true", function()
			FeatureFlag.set('dev', true)
			assert.is_true(FeatureFlag.get('dev'))
		end)

		it("should set a flag to false", function()
			FeatureFlag.set('dev', false)
			assert.is_false(FeatureFlag.get('dev'))
		end)

		it("should set a flag to string", function()
			FeatureFlag.set('dev', 'foobar')
			assert.are_equal('foobar', FeatureFlag.get('dev'))
		end)

		it("should reset a flag to its default value", function()
			FeatureFlag.set('dev', nil)
			assert.are_equal(FeatureFlag.getConfig('dev').defaultValue, FeatureFlag.get('dev'))
		end)
	end)

	describe("with", function()
		it("should run a function with temporary flag settings", function()
			local function testFunc()
				assert.is_true(FeatureFlag.get('dev'))
			end
			FeatureFlag.with({dev = true}, testFunc)
			assert.are_equal(FeatureFlag.getConfig('dev').defaultValue, FeatureFlag.get('dev'))
		end)
	end)

	describe("getConfig", function()
		it("should retrieve the configuration of a known flag", function()
			local config = FeatureFlag.getConfig('dev')
			assert.is_false(config.defaultValue)
		end)

		it("should error for an unknown flag", function()
			assert.has_error(function() FeatureFlag.getConfig('unknown_flag') end)
		end)
	end)
end)
