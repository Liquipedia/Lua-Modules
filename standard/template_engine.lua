---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateEngine
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Table = require('Module:Table')

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
	local renderOrder = {
		TemplateEngine._section,
		TemplateEngine._invertedSection,
		TemplateEngine._variable,
	}

	local context = Context(model) ---@type TemplateEngineContext
	return Array.reduce(renderOrder, function (modifiedTemplate, render)
		return render(self, modifiedTemplate, context)
	end, template)
end

---Handles `{{mustache}}` `sections`.
---The section start is a key in the model.
---If it's an array then the contnet within will be displayed once for each element in the array.
---If it's a function, the function will be called.
---Otherwise, if the value is truthy then it will be rendered.
---@param template string
---@param context TemplateEngineContext
---@return string
function TemplateEngine:_section(template, context)
	return (template:gsub('{{#(.-)}}(.-){{/%1}}', function (varible, text)
		local value = context:find(varible)
		if type(value) == 'table' then
			return table.concat(Array.map(value, function (_, idx)
				return (text:gsub('{{%.}}', '{{'.. varible .. '.' .. idx .. '}}'))
			end))
		elseif type(value) == 'function' then
			return value(text) -- TODO second parameter `render`
		else
			return value and text or ''
		end
	end))
end

---Handles `{{mustache}}` `inverted sections`.
---While sections can be used to render text one or more times based on the value of the key,
---inverted sections may render text once based on the inverse value of the key.
---That is, they will be rendered if the key doesn't exist, is false, or is an empty list.
---@param template string
---@param conext TemplateEngineContext
---@return string
function TemplateEngine:_invertedSection(template, conext)
	return (template:gsub('{{^(.-)}}(.-){{/%1}}', function (varible, text)
		local value = conext:find(varible)
		if not value or (type(value) == 'table' and #value == 0) then
			return text
		end
		return ''
	end))
end

---Interpolates a template using string interpolation. Can handle nested tables.
---@param template string
---@param context TemplateEngineContext
---@return string
function TemplateEngine:_variable(template, context)
	return (template:gsub('{{([%w%.]-)}}', function(variable)
		local value = context:find(variable)
		if type(value) == 'function' then
			value = value(context.model)
		end
		return value or variable
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
