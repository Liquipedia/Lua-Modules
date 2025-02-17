---
-- @Liquipedia
-- wiki=commons
-- page=Module:FeatureFlag
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FeatureFlagConfig = mw.loadData('Module:FeatureFlag/Config')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

--[[
Module for reading and setting feature flags. Feature flags are boolean values
that control whether certain code paths pertaining to new features are enabled.
To create a new feature flag, add an entry to Module:FeatureFlag/Config.

Usage:
Feature flags can be read and written to. If the value has not been set, then
the configured default value is used.

FeatureFlag.get('chiseled_face')
FeatureFlag.set('thick_mustache', true)

Feature flags can be applied temporarily inside a scope.

FeatureFlag.with({rugged_grin = true}, function()
	-- ...
end)

Feature flags are also available in wikicode, with the exception of the
configured default value which is only available in lua.

{{#var:feature_chiseled_face}}
{{#vardefine:feature_thick_mustache|1}}

]]
local FeatureFlag = {}

local cachedFlags = {}

---Retrieves the boolean value of a feature flag. If the flag has not been
---previously set, this returns the configured default value of the flag.
---@param flag string
---@return boolean
function FeatureFlag.get(flag)
	if cachedFlags[flag] == nil then
		cachedFlags[flag] = FeatureFlag._get(flag)
	end
	return cachedFlags[flag]
end

---@param flag string
---@return boolean|string
function FeatureFlag._get(flag)
	local config = FeatureFlag.getConfig(flag)
	return Logic.nilOr(
		Logic.readBoolOrNil(mw.ext.VariablesLua.var('feature_' .. flag)),
		Logic.nilIfEmpty(mw.ext.VariablesLua.var('feature_' .. flag)),
		config.defaultValue,
		false
	)
end

---Sets the value of a feature flag. If value is nil, then this resets the value to the configured default.
---@param flag string
---@param value boolean|string|nil
function FeatureFlag.set(flag, value)
	FeatureFlag.getConfig(flag)
	if Logic.readBoolOrNil(value) ~= nil then
		mw.ext.VariablesLua.vardefine('feature_' .. flag, value and '1' or '0')
	elseif value ~= nil then
		---@cast value string
		mw.ext.VariablesLua.vardefine('feature_' .. flag, value)
	else
		mw.ext.VariablesLua.vardefine('feature_' .. flag, '')
	end
	cachedFlags[flag] = nil
end

---Runs a function inside a scope where the specified flags are set.
---@generic V
---@param flags? {[string]: boolean|string}
---@param f fun(): V
---@return V|Error
function FeatureFlag.with(flags, f)
	if Table.isEmpty(flags) then
		return f()
	end
	---@cast flags -nil

	-- Remember previous flags
	local oldFlags = Table.map(flags, function(flag, value)
		return flag, mw.ext.VariablesLua.var('feature_' .. flag)
	end)

	-- Set new flags
	for flag, value in pairs(flags) do
		FeatureFlag.set(flag, value)
	end

	return Logic.try(f)
		:finally(function()
			-- Restore previous flags
			for flag, oldValue in pairs(oldFlags) do
				mw.ext.VariablesLua.vardefine('feature_' .. flag, oldValue)
				cachedFlags[flag] = nil
			end
		end)
		:get()
end

---@param flag string
---@return {defaultValue: boolean|string}
function FeatureFlag.getConfig(flag)
	local config = FeatureFlagConfig[flag]
	if not config then
		error('Unrecognized feature flag \'' .. flag .. '\'', 2)
	end
	return config
end

---Clears the cache of feature flags. This is useful for testing.
function FeatureFlag.clearCache()
	cachedFlags = {}
end

return FeatureFlag
