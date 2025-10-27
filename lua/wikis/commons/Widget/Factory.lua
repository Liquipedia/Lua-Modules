---
-- @Liquipedia
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')

local WidgetFactory = {}

---@param args {widget: string, children: any, [any]:any}
---@return Widget
function WidgetFactory.fromTemplate(args)
	local widgetClass = args.widget
	args.widget = nil

	local WidgetClass = Lua.requireIfExists('Module:Widget/' .. widgetClass)
	assert(WidgetClass, 'Widget not found: ' .. widgetClass)
	---@cast WidgetClass Widget

	local propSpec = WidgetClass.propSpec
	args.children = WidgetFactory._parseTable(args.children) or args.children

	for propName, prop in pairs(propSpec) do
		if prop.type == 'integer' then
			args[propName] = WidgetFactory._parseInteger(args[propName])
		elseif prop.type == 'string' then
			args[propName] = WidgetFactory._parseString(args[propName])
		elseif prop.type == 'table' then
			args[propName] = WidgetFactory._parseTable(args[propName])
		elseif prop.type == 'boolean' then
			args[propName] = WidgetFactory._parseBoolean(args[propName])
		end
	end

	return WidgetClass(args)
end

---@param integer any
---@return integer|nil
function WidgetFactory._parseInteger(integer)
	if type(integer) == 'number' then
		return integer
	end
	return tonumber(integer)
end

---@param string any
---@return string|nil
function WidgetFactory._parseString(string)
	if type(string) == 'string' then
		return string
	end
	return tostring(string)
end

---@param table any
---@return table|nil
function WidgetFactory._parseTable(table)
	if type(table) == 'table' then
		return table
	elseif type(table) == 'string' then
		local parsedTable, parsingError = Json.parseStringified(table)
		if not parsingError then
			return parsedTable
		end
	end
	return nil
end

---@param boolean any
---@return boolean|nil
function WidgetFactory._parseBoolean(boolean)
	if type(boolean) == 'boolean' then
		return boolean
	end
	return Logic.readBool(boolean)
end

return Class.export(WidgetFactory, {exports = {'fromTemplate'}})
