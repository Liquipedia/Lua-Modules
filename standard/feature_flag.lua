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

--[[
Retrieves the boolean value of a feature flag. If the flag has not been
previously set, this returns the configured default value of the flag.
]]
function FeatureFlag.get(flag)
	local config = FeatureFlag.getConfig(flag)
	return Logic.nilOr(
		Logic.readBoolOrNil(mw.ext.VariablesLua.var('feature_' .. flag)),
		config.defaultValue,
		false
	)
end

--[[
Sets the value of a feature flag. If value is nil, then this resets the value
to the configured default.
]]
function FeatureFlag.set(flag, value)
	FeatureFlag.getConfig(flag)
	if value ~= nil then
		mw.ext.VariablesLua.vardefine('feature_' .. flag, value and '1' or '0')
	else
		mw.ext.VariablesLua.vardefine('feature_' .. flag, '')
	end
end

--[[
Runs a function inside a scope where the specified flags are set.
]]
function FeatureFlag.with(flags, f)
	-- Remember previous flags
	local oldFlags = Table.map(flags, function(flag, value)
		return flag, mw.ext.VariablesLua.var('feature_' .. flag)
	end)

	-- Set new flags
	for flag, value in ipairs(flags) do
		FeatureFlag.set(flag, value)
	end

	return Logic.try(f)
		.finally(function()
			-- Restore previous flags
			for flag, oldValue in ipairs(oldFlags) do
				mw.ext.VariablesLua.vardefine('feature_' .. flag, oldValue)
			end
		end)
		.get()
end

function FeatureFlag.getConfig(flag)
	local config = FeatureFlagConfig[flag]
	if not config then
		error('Unrecognized feature flag \'' .. flag .. '\'', 2)
	end
	return config
end

return FeatureFlag
