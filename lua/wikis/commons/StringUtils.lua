---
-- @Liquipedia
-- page=Module:StringUtils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = {}

---@param str string
---@param start string
---@return boolean
function String.startsWith(str, start)
	return str:sub(1, #start) == start --str:find('^' .. start) ~= nil
end

---@param str string
---@param ending string
---@return boolean
function String.endsWith(str, ending)
	return ending == '' or str:sub(-#ending) == ending
end

---@param inputstr string?
---@param sep string?
---@return string[]
function String.split(inputstr, sep)
	if inputstr ~= nil then
		if sep == nil then
			sep = '%s'
		end
		inputstr = inputstr:gsub(sep, '&')
		local t = {}
		local i = 1
		for str in string.gmatch(inputstr, '([^&]+)') do
			t[i] = str
			i = i + 1
		end
		return t
	else
		return {''}
	end
end

--- need to escape `.()[]+-%` with % for 'match'
---@param str string
---@param match string
---@return boolean
function String.contains(str, match)
	return string.find(str, match) ~= nil
end

--- Trims a string from tabs (`\t`), new lines (`\n`), carriage returns (`\r`),
--- form feeds (`\f`), whitespaces (` `) and non-breaking spaces (`&nbsp;`)
---@param str string
---@return string
function String.trim(str)
	-- `\t\r\n\f ` is the default charset
	-- `\194\160` is the non-breaking space (&nsbp;)
	return mw.text.trim(str, "\t\r\n\f \194\160")
end

---@param str string?
---@return string?
function String.nilIfEmpty(str)
	return str ~= '' and str or nil
end

---@param str string?
---@return boolean
function String.isEmpty(str)
	return str == nil or str == ''
end


---@param str string?
---@return boolean
function String.isNotEmpty(str)
	return str ~= nil and str ~= ''
end

---transforms a wiki code list:
---
--- * text
--- * text
---
---into a html list (with ul/li tags)
---@param str string?
---@param delimiter string?
---@return string
function String.convertWikiListToHtmlList(str, delimiter)
	if String.isEmpty(str) then
		return ''
	end
	---@cast str -nil
	if String.isEmpty(delimiter) then
		delimiter = '*'
	end
	local strArray = mw.text.split(str, delimiter)
	local list = mw.html.create('ul')
	for _, item in ipairs(strArray) do
		if not String.isEmpty(item) then
			list:tag('li'):wikitext(item)
		end
	end
	return tostring(list)
end

--- Create a string with string interpolation
---
--- String.interpolation('I\'m ${age} years old', {age = 40})
--- Returns `I'm 40 years old`
---
--- Inspiration: http://lua-users.org/wiki/StringInterpolation
---@param s string
---@param tbl table
---@return string
function String.interpolate(s, tbl)
	return (
		s:gsub('($%b{})',
			function(w)
				return tbl[w:sub(3, -2)] or w
			end
		)
	)
end

---Uppercase the first letter of a string
---@param str string
---@return string
function String.upperCaseFirst(str)
	return mw.getContentLanguage():ucfirst(str)
end

return String
