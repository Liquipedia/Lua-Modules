---
-- @Liquipedia
-- page=Module:Widget/ControlsSettingsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local SETTINGS_LINK = 'Control settings'

---@alias ColumnConfig
---| {key: string, title: string}
---| {keys: ({key: string} | string)[], title: string}
---@alias ColumnValue {title: string, value: fun(data: {[string]: string?}): string?}

---@class ControlsSettingsTableWidget: Widget
---@field args {[string]: string?}
---@field columnConfig ColumnConfig[]
---@field frame table
local ControlsSettingsTableWidget = Class.new(Widget,
	function(self, columnConfig, args, frame)
		self.columnConfig = columnConfig
		self.args = args
		self.frame = frame or mw.getCurrentFrame()
	end
)

---@return Widget?
function ControlsSettingsTableWidget:render()
	local header = self:renderHeader()
	local footer = self:renderFooter()
	local visibleColumns = self:getVisibleColumns()

	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = {self:renderTable(header, footer, visibleColumns)}
	}
end

---@return string
function ControlsSettingsTableWidget:renderHeader()
	local args = self.args
	local frame = self.frame
	local header = Page.exists(SETTINGS_LINK) and '[['.. SETTINGS_LINK ..']] ' or SETTINGS_LINK..' '
	if args.ref == 'insidesource' then
		header = header .. frame:callParserFunction{
			name = '#tag',
			args = { 'ref', Template.safeExpand(frame, 'inside source') }
		}
	elseif args.ref then
		header = header .. frame:callParserFunction{
			name = '#tag',
			args = { 'ref', args['ref'] }
		}
	end
	return header .. " <small>([[List of player control settings|list of]])</small>'''"
end

---@return string
function ControlsSettingsTableWidget:renderFooter()
	local args = self.args
	if args.date then
		local year, month, day = (args.date):match('(%d+)-(%d+)-(%d+)')
		local dayAgo = math.floor((os.time() - os.time{year=year, month=month, day=day}) / 86400)
		return '<i>Last updated on '.. args.date ..' (' .. dayAgo ..' days ago).</i>'
	end
	return '<span class="cinnabar-text"><i>No date of last update specified!</i></span>'
end

---@return ColumnValue[]
function ControlsSettingsTableWidget:getVisibleColumns()
	return Array.flatMap(self.columnConfig, function(config)
		local column = self:makeColumn(config)
		return String.isNotEmpty(column.value(self.args)) and { column } or {}
	end)
end

---@param config ColumnConfig
---@return ColumnValue
function ControlsSettingsTableWidget:makeColumn(config)
	return {
		title = config.title,
		value = function(data)
			if config.keys then
				local values = {}
				local hasValue = false
				for _, item in ipairs(config.keys) do
					if type(item) == 'table' then
						local formatted = self:formatKeyValue(item.key, data)
						table.insert(values, formatted or '-')
						if formatted then hasValue = true end
					else
						table.insert(values, item)
					end
				end
				return hasValue and table.concat(values) or nil
			elseif config.key then
				return self:formatKeyValue(config.key, data)
			end
		end
	}
end

---@param key string
---@param data {[string]: string?}
---@return string?
function ControlsSettingsTableWidget:formatKeyValue(key, data)
	local keyValue = data[key:lower()]
	if not keyValue or String.isEmpty(keyValue) then
		return nil
	end
	if data.controller and data.controller:lower() == 'kbm' then
		return '<kbd>' .. keyValue .. '</kbd>'
	end
	return '[[File:' .. self:getImageName(data.controller, keyValue) .. '.svg|' .. key .. '|link=]]'
end

---@param device string?
---@param key string?
---@return string?
function ControlsSettingsTableWidget:getImageName(device, key)
	return Template.safeExpand(self.frame, 'Button translation', {(device or ''):lower(), (key or ''):lower()})
end

---@param header string
---@param footer string
---@param visibleColumns ColumnValue[]
---@return Widget
function ControlsSettingsTableWidget:renderTable(header, footer, visibleColumns)
	return HtmlWidgets.Table{
		classes = {'wikitable', 'controls-responsive-table'},
		css = {['table-layout'] = 'auto'},
		children = WidgetUtil.collect(
			HtmlWidgets.Tr{children = {
				HtmlWidgets.Th{
					attributes = {colspan = #self.columnConfig},
					children = header
					}
			}},
			HtmlWidgets.Tr{children = Array.map(visibleColumns, function(column)
				return HtmlWidgets.Th{children = column.title}
			end)},
			HtmlWidgets.Tr{children = Array.map(visibleColumns, function(column)
				return HtmlWidgets.Td{
					attributes = {['data-label'] = column.title},
					children = column.value(self.args)
					}
			end)},
			HtmlWidgets.Tr{children = {
				HtmlWidgets.Th{
					attributes = {colspan = #self.columnConfig},
					css = {
						['font-size'] = '85%',
						padding = '2px',
					},
					children = footer
				}
			}}
		)
	}
end

return ControlsSettingsTableWidget
