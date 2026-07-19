---
-- @Liquipedia
-- page=Module:TextSanitizer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute

local TextSanitizer = {}

local NAME_SANITIZER = {
	['<.->'] = '', -- All html tags and their attributes
	['&nbsp;'] = ' ', -- Non-breaking space
	['&zwj;'] = '', -- Zero width joiner
	['—'] = '-', -- Non-breaking hyphen
	['&shy;'] = '', -- Soft hyphen
}

---Replaces a set of html entities with ansi characters.
---Removes all html tags and their attributes.
---@param name string?
---@return string?
function TextSanitizer.stripHTML(name)
	if not name then
		return
	end

	local sanitizedName = name
	for search, replace in pairs(NAME_SANITIZER) do
		sanitizedName = sanitizedName:gsub(search, replace)
	end

	return sanitizedName
end

return TextSanitizer
