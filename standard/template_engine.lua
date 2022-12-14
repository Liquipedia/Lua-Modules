---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateEngine
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')
local Table = require('Module:Table')

---@class TemplateEngine 
---Subset implementation of `{{mustache}} templates`
---https://mustache.github.io/mustache.5.html
local TemplateEngine = {}

---Created the html output from a given template string and table input.
---@param template string
---@param model table
---@return string
function TemplateEngine.render(template, model)
	return TemplateEngine._interpolate(TemplateEngine._foreach(template, model), model)
end

---Handles foreach loops by replacing
---```{{#y}}{{.}}{{/y}}```
---with `${y.foo}${y.bar}` given that key `y` in the model is a table with two keys, `foo` and `bar`.
---@param template string
---@param model table
---@return string
function TemplateEngine._foreach(template, model)
	return (template:gsub('{{#(.-)}}(.-){{/%1}}', function (list, text)
		local strBuilder = {}
		for value in pairs(model[list]) do
			table.insert(strBuilder, TemplateEngine._interpolate(text, {['.'] = '{{'.. list .. '.' .. value .. '}}'}))
		end
		return table.concat(strBuilder)
	end))
end

---Interpolates a template using string interpolation. Can handle nested tables.
---@param template string
---@param model table
---@return string
function TemplateEngine._interpolate(template, model)
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
