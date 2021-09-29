---
-- @Liquipedia
-- wiki=commons
-- page=Module:StringUtils
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = {}

function String.startsWith(str, start)
	return str:sub(1, #start) == start --str:find('^' .. start) ~= nil
end

function String.endsWith(str, ending)
	return ending == '' or str:sub(-#ending) == ending
end

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

-- need to escape .()[]+-% with % for 'match'
function String.contains(str, match)
	return string.find(str, match) ~= nil
end

function String.trim(str)
	return (str:gsub('^%s*(.-)%s*$', '%1'))
end

function String.nilIfEmpty(str)
	return str ~= '' and str or nil
end

function String.isEmpty(str)
	return str == nil or str == ''
end

-- index counts up from 0
function String.explode(str, delimiter, index)
	return String.split(str, delimiter)[index + 1] or ''
end

--transforms a wiki code list
---->> * text
---->> * text
--into a html list (with ul/li tags)
function String.convertWikiListToHtmlList(str, delimiter)
	if String.isEmpty(str) then
		return ''
	end
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

return String
