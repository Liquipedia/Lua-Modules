---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateEngine
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

---@class TemplateEngine
---Subset implementation of `{{mustache}} templates`.
---https://mustache.github.io/mustache.5.html
local TemplateEngine = {}

---Created the html output from a given template string and table input.
---@param template string
---@param model table
---@return string
function TemplateEngine.render(template, model)
	return TemplateEngine._interpolate(TemplateEngine._section(template, model), model)
end

---Handles mustache `sections`
---A section start has two possible inputs. Either 
---@param template string
---@param model table
---@return string
function TemplateEngine._section(template, model)
	return (template:gsub('{{#(.-)}}(.-){{/%1}}', function (varible, text)
		if type(model[varible]) == 'table' then
			return table.concat(Array.map(model[varible], function (_, idx)
				return TemplateEngine._interpolate(text, {['.'] = '{{'.. varible .. '.' .. idx .. '}}'})
			end))
		elseif type(model[varible]) == 'function' then
			return model[varible](text) -- TODO second parameter `render`
		else
			return model[varible] and text or ''
		end
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
