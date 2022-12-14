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

	return Array.reduce(renderOrder, function (modifiedTemplate, render)
		return render(self, modifiedTemplate, model)
	end, template)
end

---Handles `{{mustache}}` `sections`.
---The section start is a key in the model.
---If it's an array then the contnet within will be displayed once for each element in the array.
---If it's a function, the function will be called.
---Otherwise, if the value is truthy then it will be rendered.
---@param template string
---@param model table
---@return string
function TemplateEngine:_section(template, model)
	return (template:gsub('{{#(.-)}}(.-){{/%1}}', function (varible, text)
		if type(model[varible]) == 'table' then
			return table.concat(Array.map(model[varible], function (_, idx)
				return self:_variable(text, {['.'] = '{{'.. varible .. '.' .. idx .. '}}'})
			end))
		elseif type(model[varible]) == 'function' then
			return model[varible](text) -- TODO second parameter `render`
		else
			return model[varible] and text or ''
		end
	end))
end

---Handles `{{mustache}}` `inverted sections`.
---While sections can be used to render text one or more times based on the value of the key,
---inverted sections may render text once based on the inverse value of the key.
---That is, they will be rendered if the key doesn't exist, is false, or is an empty list.
---@param template string
---@param model table
---@return string
function TemplateEngine:_invertedSection(template, model)
	return (template:gsub('{{^(.-)}}(.-){{/%1}}', function (varible, text)
		local value = model[varible]
		if not value or (type(value) == 'table' and #value == 0) then
			return text
		end
		return ''
	end))
end

---Interpolates a template using string interpolation. Can handle nested tables.
---@param template string
---@param model table
---@return string
function TemplateEngine:_variable(template, model)
	local function toNumberIfNumeric(number)
		return tonumber(number) or number
	end
	return (
		template:gsub('{{([%w%.]-)}}',
			function(w)
				if w == '.' then
					return model['.']
				end
				local path = Table.mapValues(mw.text.split(w, '.', true), toNumberIfNumeric)
				local key = Table.extract(path, #path)
				local finalTbl =  Table.getByPath(model, path)
				return finalTbl and finalTbl[key] or w
			end
		)
	)
end

return TemplateEngine
