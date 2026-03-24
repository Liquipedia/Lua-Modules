---
-- @Liquipedia
-- page=Module:ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local ButtonTranslation = Lua.import('Module:Links/ButtonTranslation')
local Class = Lua.import('Module:Class')
local Date = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Dialog = Lua.import('Module:Widget/Basic/Dialog')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

-- table2 aliases
local Row = TableWidgets.Row
local Cell = TableWidgets.Cell
local CellHeader = TableWidgets.CellHeader
local Table2 = TableWidgets.Table
local TableBody = TableWidgets.TableBody

---@class ControlsSettingsTable
---@field config {keys: string[], title: string}[]
---@field args {[string]: string?}
local ControlsSettingsTable = Class.new(
	function(self, args, config)
		self.args = args
		self.config = config
	end
)

---@param frame table
---@return Widget
function ControlsSettingsTable.create(frame)
	local args = Arguments.getArgs(frame)
	local config = Info.controlsSettingsTable
	local controlsSettingsTable = ControlsSettingsTable(args, config)
	controlsSettingsTable:saveToLpdb()
	return controlsSettingsTable:render()
end

function ControlsSettingsTable:saveToLpdb()
	local title = mw.title.getCurrentTitle().text
	local extradata = self:generateLpdbExtradata()
	mw.ext.LiquipediaDB.lpdb_settings(title, {
		name = 'movement',
		reference = self.args.ref,
		lastupdated = self.args.date,
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
		type = (self.args.controller or ''):lower(),
	})
end

---@return {[string]: string?}
function ControlsSettingsTable:generateLpdbExtradata()
	local lpdbData = {}
	Array.forEach(self.config, function(item)
		Array.forEach(item.keys, function(key)
			lpdbData[key:lower()] = self.args[key:lower()]
		end)
	end)
	return lpdbData
end

---@return Widget
function ControlsSettingsTable:render()
	return Table2{
		children = TableBody{children = self:makeRows()},
		title = self:makeHeaderDisplay(),
		footer = self:makeWarningDisplay(),
	}
end

---@return Widget[]
function ControlsSettingsTable:makeRows()
	local nonEmptyRows = Array.filter(self.config, function(configRow)
        return Array.any(configRow.keys, function(key)
            return String.isNotEmpty(self.args[key:lower()])
        end)
    end)
    return Array.map(nonEmptyRows, function(configRow)
        local buttons = Array.map(configRow.keys, function(key)
            return self:makeButtonIcon(key) or self:makeButtonStubIcon()
        end)
        return ControlsSettingsTable:makeRow(configRow.title, buttons)
    end)
end

---@param key string
---@return Widget?
function ControlsSettingsTable:makeButtonIcon(key)
	local button = self.args[key:lower()]
	if String.isEmpty(button) then
		return nil
	end
	---@cast button string
	if self.args.controller and self.args.controller:lower() == 'kbm' then
		return HtmlWidgets.Kbd{children = button}
	end
	local imageName = self:getImageName(self.args.controller, button)
	return self:makeButtonDisplay(imageName, button)
end

---@param device string?
---@param button string?
---@return string
function ControlsSettingsTable:getImageName(device, button)
	device = Logic.nilOr(device, ''):lower()
    button = Logic.nilOr(button, ''):lower():gsub(' ', '_')
	return ButtonTranslation[device][button] or 'ImageNotFound'
end

---@param imageName string
---@param button string
---@return Widget
function ControlsSettingsTable:makeButtonDisplay(imageName, button)
	return Image{
			imageLight = imageName,
			size = 'md',
			caption = button,
			alt = button,
		}
end

---@return Widget
function ControlsSettingsTable:makeButtonStubIcon()
	return IconFa{iconName = 'no', size = 'sm'}
end

---@param title string
---@param value Widget
---@return Widget
function ControlsSettingsTable:makeRow(title, value)
	return Row{
		children = {
			CellHeader{children = title, align = 'right'},
			Cell{
				children = HtmlWidgets.Div{
					children = value,
					css = {display = 'flex', gap = '6px', ['align-items'] = 'center'}
				},
				align = 'left'
			}
		}
	}
end

---@return Widget
function ControlsSettingsTable:makeHeaderDisplay()
	return HtmlWidgets.Div{
		css = {['text-align'] = 'center'},
		children = {
			'Control settings',
			HtmlWidgets.Span{
				children = self:makeReferenceDisplay(),
				css = {['margin-left'] = '10px'}
			}
		}
	}
end

---@return Widget
function ControlsSettingsTable:makeReferenceDisplay()
	local timestamp = Date.readTimestamp(self.args.date)
	local date = timestamp and Date.formatTimestamp('M j, Y', timestamp) or '?'
	return Dialog{
			trigger =  IconFa{
				iconName = 'reference',
				size = 'sm',
			},
			title = 'Reference',
			children = HtmlWidgets.Div{
				children = {
					self:makeReferenceSource(),
					HtmlWidgets.Br{},
					HtmlWidgets.I{
						children = 'Last updated on ' .. date
					}
				}
		}
	}
end

---@return string|Widget
function ControlsSettingsTable:makeReferenceSource()
	local args = self.args
	if args.ref and args.ref:lower():gsub(' ', '') == 'insidesource' then
		return HtmlWidgets.Abbr{
			children = 'Inside source',
			attributes = {title = 'Liquipedia has gained this information from a trusted inside source'}
		}
	end
	return Logic.nilOr(self.args.ref, '?')
end

---@return Widget?
function ControlsSettingsTable:makeWarningDisplay()
	if Logic.isEmpty(self.args.ref) then
		return self:makeWarning('No reference specified!')
	elseif Logic.isEmpty(self.args.date) then
		return self:makeWarning('No date of last update specified!')
	end
	return nil
end

---@param text string
---@return Widget
function ControlsSettingsTable:makeWarning(text)
	return {HtmlWidgets.Span{
		classes = {'cinnabar-text'},
		children = {HtmlWidgets.I{children = text}},
		css = {['font-size'] = '90%'}
	}}
end

return ControlsSettingsTable
