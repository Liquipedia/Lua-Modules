---
-- @Liquipedia
-- wiki=commons
-- page=Module:TemplateEngine
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')
local Table = require('Module:Table')

local TemplateEngine = {}

---Created the html output from a given template string and table input.
---@param template string
---@param tbl table
---@return string
function TemplateEngine.eval(template, tbl)
	return TemplateEngine._interpolate(TemplateEngine._foreach(template, tbl), tbl)
end

---Handles foreach loops by replacing
---```*{foreach x in y}${x}*{end}```
---with `${y.foo}${y.bar}` given that key `y` in `tbl` input is a table with two keys, `foo` and `bar`.
---@param template string
---@param tbl table
---@return string
function TemplateEngine._foreach(template, tbl)
	local function createReplacement(list, value)
		return '${' .. String.interpolate('${list}.${val}', {list = list, val = value}) .. '}'
	end
	return (template:gsub('*{foreach (.-) in (.-)}(.-)*{end}', function (var, list, text)
		local str = ''
		for value in pairs(tbl[list]) do
			str = str .. TemplateEngine._interpolate(text, {[var] = createReplacement(list, value)})
		end
		return str
	end))
end

---Interpolates a template using string interpolation. Can handle nested tables.
---@param template string
---@param tbl table
---@return string
function TemplateEngine._interpolate(template, tbl)
	local function toNumberIfNumeric(number)
		return tonumber(number) or number
	end
	return (
		template:gsub('($%b{})',
			function(w)
				local path = Table.mapValues(mw.text.split(w:sub(3, -2), '.', true), toNumberIfNumeric)
				local key = Table.extract(path, #path)
				local finalTbl =  Table.getByPath(tbl, path)
				return finalTbl and finalTbl[key] or w
			end
		)
	)
end

return TemplateEngine
