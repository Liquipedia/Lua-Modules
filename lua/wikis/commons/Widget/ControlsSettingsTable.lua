---
-- @Liquipedia
-- page=Module:Widget/ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local ButtonTranslation = Lua.import('Module:Links/ButtonTranslation')
local Class = Lua.import('Module:Class')
local Date = Lua.import('Module:Date/Ext')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ControlsSettingsTableWidget: Widget
---@field columnConfig {keys: string[], title: string}
---@field args {[string]: string?}
---@field frame table
local ControlsSettingsTableWidget = Class.new(Widget,
	function(self, columnConfig, args, frame)
		self.columnConfig = columnConfig
		self.args = args
		self.frame = frame or mw.getCurrentFrame()
	end
)

---@return Widget
function ControlsSettingsTableWidget:render()
	return HtmlWidgets.Div{children = {self:renderTable()}}
end

---@return Widget
function ControlsSettingsTableWidget:renderTable()
	local columns = self:getColumns()
	local columnsNumber = #columns
	return HtmlWidgets.Table{
		classes = {'wikitable', 'controls-responsive-table'},
		children = WidgetUtil.collect(
			self:renderHeader(columnsNumber),
			self:renderColumnHeaders(columns),
			self:renderDataRow(columns),
			self:renderFooter(columnsNumber)
		)
	}
end

---@return {title: string, value: string}
function ControlsSettingsTableWidget:getColumns()
    return Array.map(self.columnConfig, function(column)
        local buttons = Array.map(column.keys, function(key)
            return self:formatToImage(self.args, key) or '-'
        end)
        local argsEmpty = Array.all(buttons, function(value)
            return value == '-'
        end)
        if argsEmpty then
            return nil
        end
        return {
            title = column.title,
            value = table.concat(buttons, ' / ')
        }
    end)
end

---@param args {[string]: string?}
---@param key string
---@return string?
function ControlsSettingsTableWidget:formatToImage(args, key)
	local buttonText = '[[File: ${image} | ${button} | link=]]'
	local button = args[key:lower()]
	if String.isEmpty(button) then
		return nil
	end
	if args.controller and args.controller:lower() == 'kbm' then
		return '<kbd>' .. button .. '</kbd>'
	end
	return String.interpolate(buttonText, {image = self:getImageName(args.controller, button), button = key})
end

---@param device string?
---@param key string?
---@return string
function ControlsSettingsTableWidget:getImageName(device, key)
	device = (device or ''):lower()
    key = (key or ''):lower():gsub(' ', '_')
	return ButtonTranslation[device][key] or 'ImageNotFound'
end

---@param columnsNumber integer
---@return Widget
function ControlsSettingsTableWidget:renderHeader(columnsNumber)
	return HtmlWidgets.Tr{children = {
		HtmlWidgets.Th{
			attributes = {colspan = columnsNumber},
			children = {
				self:makeHeaderText(),
				' ',
				HtmlWidgets.Small{children = '([[List of player control settings|list of]])'}
			}
		}
	}}
end

---@return string
function ControlsSettingsTableWidget:makeHeaderText()
	local headerText = 'Control settings ${ref}'
	local args = self.args
	local frame = self.frame
	local reference = ''
	if args.ref == 'insidesource' then
		reference = frame:extensionTag('ref', Template.safeExpand(frame, 'inside source'))
	elseif args.ref then
		reference = frame:extensionTag('ref', args['ref'])
	end
	return String.interpolate(headerText, {ref = reference})
end

---@param columns {title: string, value: string}
---@return Widget
function ControlsSettingsTableWidget:renderColumnHeaders(columns)
	return HtmlWidgets.Tr{children = Array.map(columns, function(column)
		return HtmlWidgets.Th{children = column.title}
	end)}
end

---@param columns {title: string, value: string}
---@return Widget
function ControlsSettingsTableWidget:renderDataRow(columns)
	return HtmlWidgets.Tr{children = Array.map(columns, function(column)
		return HtmlWidgets.Td{
			attributes = {['data-label'] = column.title},
			children = column.value
		}
	end)}
end

---@param columnsNumber integer
---@return Widget
function ControlsSettingsTableWidget:renderFooter(columnsNumber)
	local footerText = self:makeFooterText()
	return HtmlWidgets.Tr{children = {
		HtmlWidgets.Th{
			attributes = {colspan = columnsNumber},
			css = {['font-size'] = '85%'},
			children = String.isNotEmpty(footerText)
				and {HtmlWidgets.I{children = footerText}}
				or {HtmlWidgets.Span{
					classes = {'cinnabar-text'},
					children = {HtmlWidgets.I{children = 'No date of last update specified!'}}
				}}
		}
	}}
end

---@return string?
function ControlsSettingsTableWidget:makeFooterText()
	local footerText = 'Last updated on ${date} (${daysAgo} days ago).'
	local args = self.args
	if args.date then
		local currentTimestamp = Date.getCurrentTimestamp()
		local targetTimestamp = Date.readTimestamp(args.date)
		local daysAgo = math.floor((currentTimestamp - targetTimestamp) / 86400)
		return String.interpolate(footerText, {date = args.date, daysAgo = daysAgo})
	end
	return nil
end

return ControlsSettingsTableWidget
