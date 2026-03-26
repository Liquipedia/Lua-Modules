---
-- @Liquipedia
-- page=Module:ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info')

local ControlsSettingsTableWidget = Lua.import('Module:Widget/ControlsSettingsTable')

local ControlsSettingsTable = Class.new()

---@param frame table
---@return Widget
function ControlsSettingsTable.create(frame)
	local args = Arguments.getArgs(frame)
	local config = Info.controlsSettingsTable
	local widget = ControlsSettingsTableWidget(config, args)
	ControlsSettingsTable.saveToLpdb(config, args)
	return widget:render()
end

---@param config {keys: string[], title: string}
---@param args {[string]: string?}
function ControlsSettingsTable.saveToLpdb(config, args)
	local title = mw.title.getCurrentTitle().text
	local extradata = ControlsSettingsTable.generateLpdbExtradata(config, args)
	mw.ext.LiquipediaDB.lpdb_settings(title, {
		name = 'movement',
		reference = args.ref,
		lastupdated = args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
		type = (args.controller or ''):lower(),
	})
end

---@param config {keys: string[], title: string}
---@param args {[string]: string?}
---@return {[string]: string?}
function ControlsSettingsTable.generateLpdbExtradata(config, args)
	local lpdbData = {}
	Array.forEach(config, function(item)
		Array.forEach(item.keys, function(key)
			lpdbData[key:lower()] = args[key:lower()]
		end)
	end)
	return lpdbData
end

return ControlsSettingsTable
