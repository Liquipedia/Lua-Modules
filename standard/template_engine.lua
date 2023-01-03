---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateEngine
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

---Return true if the input is a table in array format
---@param array any
---@return boolean
local function isArray(array)
	if type(array) ~= 'table' then
		return false
	end
	return Table.size(array) == #array
end

---@class TemplateEngine
---Subset implementation of `{{mustache}} templates`.
---https://mustache.github.io/mustache.5.html
local TemplateEngine = Class.new()

---@class TemplateEngineContext
local Context = Class.new(function(self, ...) self:init(...) end)

---Created the html output from a given template and a model input.
---@param template string
---@param model table
---@return string
function TemplateEngine:render(template, model)
	local context = Context(model) ---@type TemplateEngineContext
	return TemplateEngine:_subRender(template, context)
end

---Renders a given template based on a TemplateEngineContext
---@param template string
---@param context TemplateEngineContext
---@return string
function TemplateEngine:_subRender(template, context)
	local renderOrder = {
		TemplateEngine._section,
		TemplateEngine._invertedSection,
		TemplateEngine._variable,
	}

	return Array.reduce(renderOrder, function (modifiedTemplate, render)
		return render(self, modifiedTemplate, context)
	end, template)
end

---Handles `{{mustache}}` `sections`.
---The section start is a key in the model.
---If it's an array then the content within will be displayed once for each element in the array.
---If it's a non-array table, the content with be rendered with this table as model.
---If it's a function, the function will be called.
---Otherwise, if the value is truthy then the section content will be rendered.
---@param template string
---@param context TemplateEngineContext
---@return string
function TemplateEngine:_section(template, context)
	return (template:gsub('{{#(.-)}}(.-){{/%1}}', function (varible, text)
		local value = context:find(varible)
		if type(value) == 'table' then
			if isArray(value) then
				return table.concat(Array.map(value, function (val)
					return self:_subRender(text, Context(val, context))
				end))
			else
				return self:_subRender(text, Context(value, context))
			end
		elseif type(value) == 'function' then
			return value(text, function(newText)
				return self:_subRender(newText, context)
			end)
		else
			return value and self:_subRender(text, context) or ''
		end
	end))
end

---Handles `{{mustache}}` `inverted sections`.
---While sections can be used to render text one or more times based on the value of the key,
---inverted sections may render text once based on the inverse value of the key.
---That is, they will be rendered if the key doesn't exist, is false, or is an empty list.
---@param template string
---@param context TemplateEngineContext
---@return string
function TemplateEngine:_invertedSection(template, context)
	return (template:gsub('{{^(.-)}}(.-){{/%1}}', function (varible, text)
		local value = context:find(varible)
		if not value or (type(value) == 'table' and isArray(value) and #value == 0) then
			return self:_subRender(text, context)
		end
		return ''
	end))
end

---Handles `{{mustache}}` `variables` & `comments`.
---@param template string
---@param context TemplateEngineContext
---@return string
function TemplateEngine:_variable(template, context)
	return (template:gsub('{{([!%&]?)([%w%. ]-)}}', function(modifier, variable)
		if modifier == '!' then
			-- {{! Comment}}
			return ''
		end
		local escape = modifier ~= '&'
		local value = context:find(variable)
		if type(value) == 'function' then
			value = value(context.model)
		end
		value = value or variable
		return escape and mw.text.nowiki(value) or value
	end))
end

function Context:init(model, parent)
	self.model = model
	self.parent = parent
end

function Context:find(variableName)
	if variableName == '.' then
		return self.model
	end

	local function toNumberIfNumeric(number)
		return tonumber(number) or number
	end

	local context = self
	while context do
		local path = Table.mapValues(mw.text.split(variableName, '.', true), toNumberIfNumeric)
		local key = Table.extract(path, #path)
		local tbl =  Table.getByPath(context.model, path)
		if tbl[key] then
			return tbl[key]
		end
		context = context.parent
	end
end

return TemplateEngine
