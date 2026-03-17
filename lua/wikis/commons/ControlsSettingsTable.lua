---
-- @Liquipedia
-- page=Module:ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')

local ControlsSettingsTableWidget = Lua.import('Module:Widget/ControlsSettingsTable')

local ControlsSettingsTable = Class.new()

---@param lpdbConfig string[]
---@param columnConfig ColumnConfig[]
---@param frame table
---@return Widget?
function ControlsSettingsTable.create(lpdbConfig, columnConfig, frame)
	local args = Arguments.getArgs(frame)
	local widget = ControlsSettingsTableWidget(columnConfig, args)
	ControlsSettingsTable.saveToLpdb(lpdbConfig, args)
	return widget:tryMake()
end

---@param lpdbConfig string[]
---@param args {[string]: string?}
function ControlsSettingsTable.saveToLpdb(lpdbConfig, args)
	local title = mw.title.getCurrentTitle().text
	local extradata = ControlsSettingsTable.generateLpdbExtradata(lpdbConfig, args)
	mw.ext.LiquipediaDB.lpdb_settings(title, {
		name = 'movement',
		reference = args.ref,
		lastupdated = args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
		type = (args.controller or ''):lower(),
	})
end

---@param lpdbConfig string[]
---@param args {[string]: string?}
---@return {[string]: string?}
function ControlsSettingsTable.generateLpdbExtradata(lpdbConfig, args)
	local result = {}
	for _, key in ipairs(lpdbConfig) do
		result[key:lower()] = args[key:lower()]
	end
	return result
end

return ControlsSettingsTable
