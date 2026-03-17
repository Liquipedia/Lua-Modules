---
-- @Liquipedia
-- page=Module:ControlsSettingsTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')

local ControlsSettingsTable = Lua.import('Module:ControlsSettingsTable')

local CustomControlsSettingsTable = Class.new(ControlsSettingsTable)

---@type string[]
local LPDB_CONFIG = {}
--local LPDB_CONFIG = {'Accelerate', 'Brake', 'Steering'}

---@type ColumnConfig[]
local BASE_COLUMN_CONFIG = {}
--[[
local BASE_COLUMN_CONFIG = {
	{key = 'Steering', title = 'Steering'},
	{keys = {{key = 'Accelerate'}, ' / ', {key = 'Brake'}}, title = 'Accelerate/Brake'}
}
--]]

---@param args {[string]: string?}
---@return ColumnConfig[]
local function makeColumnConfig(args)
	local COLUMN_CONFIG = {}
	for _, col in ipairs(BASE_COLUMN_CONFIG) do
		table.insert(COLUMN_CONFIG, col)
	end

	return COLUMN_CONFIG
end

---@param frame table
---@return Widget?
function CustomControlsSettingsTable.create(frame)
	local args = Arguments.getArgs(frame)
	local COLUMN_CONFIG = makeColumnConfig(args)
	return ControlsSettingsTable.create(LPDB_CONFIG, COLUMN_CONFIG, frame)
end

return CustomControlsSettingsTable
