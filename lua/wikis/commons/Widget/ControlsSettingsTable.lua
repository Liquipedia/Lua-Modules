---
-- @Liquipedia
-- page=Module:Widget/ControlsSettingsTableWidget
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local ButtonTranslation = Lua.import('Module:Icon/ButtonTranslation')
local Class = Lua.import('Module:Class')
local Date = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Dialog = Lua.import('Module:Widget/Basic/Dialog')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Widget = Lua.import('Module:Widget')

-- table2 aliases
local Row = TableWidgets.Row
local Cell = TableWidgets.Cell
local CellHeader = TableWidgets.CellHeader
local Table2 = TableWidgets.Table
local TableBody = TableWidgets.TableBody

---@class ControlsSettingsTableWidget: Widget
---@field config {keys: string[], title: string}
---@field args {[string]: string?}
local ControlsSettingsTableWidget = Class.new(Widget,
	function(self, config, args)
		self.config = config
		self.args = args
	end
)

---@return Widget
function ControlsSettingsTableWidget:render()
	return Table2{
		children = TableBody{children = self:_makeRows()},
		title = self:_makeHeaderDisplay(),
		footer = self:_makeWarningDisplay()
	}
end

---@private
---@return Widget[]
function ControlsSettingsTableWidget:_makeRows()
	local nonEmptyRows = Array.filter(self.config, function(configRow)
		return Array.any(configRow.keys, function(key)
			return String.isNotEmpty(self.args[key:lower()])
		end)
	end)
	return Array.map(nonEmptyRows, function(configRow)
		local buttons = Array.map(configRow.keys, function(key)
			return self:_makeButtonIcon(key) or self:_makeButtonStubIcon()
		end)
		return ControlsSettingsTableWidget:_makeRow(configRow.title, buttons)
	end)
end

---@private
---@param key string
---@return Widget?
function ControlsSettingsTableWidget:_makeButtonIcon(key)
	local button = self.args[key:lower()]
	if String.isEmpty(button) then
		return nil
	end
	---@cast button string
	if self.args.controller and self.args.controller:lower() == 'kbm' then
		return HtmlWidgets.Kbd{children = button}
	end
	local imageName = self:_getImageName(self.args.controller, button)
	return self:_makeButtonDisplay(imageName, button)
end

---@private
---@param device string?
---@param button string?
---@return string
function ControlsSettingsTableWidget:_getImageName(device, button)
	device = Logic.nilOr(device, ''):lower()
	button = Logic.nilOr(button, ''):lower():gsub(' ', '_')
	return ButtonTranslation[device][button] or 'ImageNotFound'
end

---@private
---@param imageName string
---@param button string
---@return Widget
function ControlsSettingsTableWidget:_makeButtonDisplay(imageName, button)
	return Image{
		imageLight = imageName,
		size = 'md',
		caption = button,
		alt = button
	}
end

---@private
---@return Widget
function ControlsSettingsTableWidget:_makeButtonStubIcon()
	return IconFa{iconName = 'no', size = 'sm'}
end

---@private
---@param title string
---@param value Widget
---@return Widget
function ControlsSettingsTableWidget:_makeRow(title, value)
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

---@private
---@return Widget
function ControlsSettingsTableWidget:_makeHeaderDisplay()
	return HtmlWidgets.Div{
		css = {['text-align'] = 'center'},
		children = {
			'Control settings',
			HtmlWidgets.Span{
				children = self:_makeReferenceDisplay(),
				css = {['margin-left'] = '10px'}
			}
		}
	}
end

---@private
---@return Widget
function ControlsSettingsTableWidget:_makeReferenceDisplay()
	local timestamp = Date.readTimestamp(self.args.date)
	local date = timestamp and Date.formatTimestamp('M j, Y', timestamp) or '?'
	return Dialog{
		trigger = IconFa{
			iconName = 'reference',
			size = 'sm'
		},
		title = 'Reference',
		children = HtmlWidgets.Div{
			children = {
				self:_makeReferenceSource(),
				HtmlWidgets.Br{},
				HtmlWidgets.I{
					children = 'Last updated on ' .. date
				}
			}
		}
	}
end

---@private
---@return string|Widget
function ControlsSettingsTableWidget:_makeReferenceSource()
	local args = self.args
	if args.ref and args.ref:lower():gsub(' ', '') == 'insidesource' then
		return HtmlWidgets.Abbr{
			children = 'Inside source',
			attributes = {title = 'Liquipedia has gained this information from a trusted inside source'}
		}
	end
	return Logic.nilOr(self.args.ref, '?')
end

---@private
---@return Widget?
function ControlsSettingsTableWidget:_makeWarningDisplay()
	if Logic.isEmpty(self.args.ref) then
		return self:_makeWarning('No reference specified!')
	elseif Logic.isEmpty(self.args.date) then
		return self:_makeWarning('No date of last update specified!')
	end
	return nil
end

---@private
---@param text string
---@return Widget
function ControlsSettingsTableWidget:_makeWarning(text)
	return {HtmlWidgets.Span{
		classes = {'cinnabar-text'},
		children = {HtmlWidgets.I{children = text}},
		css = {['font-size'] = '90%'}
	}}
end

return ControlsSettingsTableWidget
