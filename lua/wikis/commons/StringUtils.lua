---
-- @Liquipedia
-- page=Module:StringUtils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = {}

---Returns true if `start` is a prefix of `str`.
---@param str string
---@param start string
---@return boolean
function String.startsWith(str, start)
	return str:sub(1, #start) == start --str:find('^' .. start) ~= nil
end

---Returns true if `ending` is a suffix of `str`.
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

---Whether a Ustring pattern only consists of ASCII characters that match themselves.
---A quantifier on its own (e.g. `-`) has nothing to quantify and matches itself.
---@param pattern string
---@param plain boolean?
---@return boolean
local function isLiteralAscii(pattern, plain)
	if pattern == '' or string.find(pattern, '[\128-\255]') then
		return false
	elseif plain == true then
		return true
	end
	return not plain and (not string.find(pattern, '[%^%$%(%)%%%.%[%]%*%+%-%?]')
		or string.find(pattern, '^[%*%+%-%?]$') ~= nil)
end

---Splits a string at a separator, with the same results as `mw.text.split`, including empty items.
---`mw.text.split` makes PHP callbacks in Scribunto, two per item. A separator of ASCII characters that are matched
---literally gives the same split with the string library, as ASCII bytes never occur within a multi-byte character.
---Other separators, and text that is not valid UTF-8, still go through `mw.text.split`.
---@param text string
---@param pattern string # A Ustring pattern, or a literal string if `plain` is true
---@param plain boolean?
---@return string[]
function String.splitText(text, pattern, plain)
	if type(text) ~= 'string' or not isLiteralAscii(pattern, plain)
		or string.find(text, '[\128-\255]') and not mw.ustring.isutf8(text) then
		return mw.text.split(text, pattern, plain)
	end
	-- A plain find is faster than `string.gmatch` with `(.-)`, which tries the separator at every position
	local items = {}
	local start = 1
	while true do
		local sepStart, sepEnd = string.find(text, pattern, start, true)
		if not sepStart then
			break
		end
		table.insert(items, string.sub(text, start, sepStart - 1))
		start = sepEnd + 1
	end
	table.insert(items, string.sub(text, start))
	return items
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
	-- `mw.text.trim` with a charset is a PHP callback in Scribunto. ASCII strings cannot contain the non-breaking space,
	-- so they are trimmed like `mw.text.trim` without a charset, minus the vertical tab its `%s` would include.
	if type(str) == 'string' and not string.find(str, '[\128-\255]') then
		return string.match(str, '^()[\t\r\n\f ]*$') and '' or string.match(str, '^[\t\r\n\f ]*(.*[^\t\r\n\f ])')
	end
	-- `\t\r\n\f ` is the default charset
	-- `\194\160` is the non-breaking space (&nsbp;)
	return mw.text.trim(str, "\t\r\n\f \194\160")
end

---Returns `nil` if the argument is `nil` or an empty string, otherwise returns the argument string itself.
---@param str string?
---@return string?
function String.nilIfEmpty(str)
	return str ~= '' and str or nil
end

---Returns true if the argument is `nil` or an empty string.
---@param str string?
---@return boolean
function String.isEmpty(str)
	return str == nil or str == ''
end

---Returns true if the argument is a nonempty string.
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
