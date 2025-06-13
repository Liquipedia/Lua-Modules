---
-- @Liquipedia
-- page=Module:Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Json = require('Module:Json')
local PageVariableNamespace = require('Module:PageVariableNamespace')

local Template = {}

---@param frame Frame
---@param title string
---@param args table?
---@param defaultTemplate any?
---@return string
---@overload fun(frame: Frame, title: string, args: table?, defaultTemplate: any): any|string
function Template.safeExpand(frame, title, args, defaultTemplate)
	local result, value = pcall(frame.expandTemplate, frame, {title = title, args = args})
	if result then
		return value
	else
		local templateName = '[[Template:' .. (title or '') .. ']]'
		return defaultTemplate or templateName
	end
end

---@param frame Frame
---@param title string
---@param args table?
---@return string?
function Template.expandTemplate(frame, title, args)
	return frame:expandTemplate{title = title, args = args}
end

--[[
Stores a value that a function would otherwise return in a place to be later
retrieved by Template.retrieveReturnValues. Used to return values across
template boundaries.
]]
---@param value wikiVariableValue|table
---@param namespace string
---@return string
function Template.stashReturnValue(value, namespace)
	local pageVars = PageVariableNamespace(namespace or 'Template.return')
	local count = tonumber(pageVars:get('count')) or 0
	count = count + 1
	pageVars:set(count, Json.stringify(value))
	pageVars:set('count', count)
	return ''
end

---Retrieves all values stashed by Template.stashReturnValue.
---@param namespace string
---@return table[]
function Template.retrieveReturnValues(namespace)
	local pageVars = PageVariableNamespace(namespace or 'Template.return')

	local count = tonumber(pageVars:get('count')) or 0
	pageVars:delete('count')

	local values = {}
	for i = 1, count do
		values[i] = Json.parse(pageVars:get(i))
		pageVars:delete(i)
	end
	return values
end

--[[
Variant of Template.stashReturnValue suitable for use by #invoke. Stores the
arguments of a template call in a place to be later retrieved by
Template.retrieveReturnValues. {{#invoke:Template|stashArgs}} has the same
interface as {{#invoke:Json|fromArgs}}.

Usage:

{{#invoke:Template|stashArgs|foo=3|namespace=Magpie}}

will make {foo = '3'} available for retrival via Template.retrieveReturnValues('Magpie') .

]]
---@param frame Frame
---@return string
function Template.stashArgs(frame)
	local args = Arguments.getArgs(frame)
	local namespace = args.namespace
	args.namespace = nil
	return Template.stashReturnValue(args, namespace)
end

return Template
