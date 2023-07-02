---
-- @Liquipedia
-- wiki=commons
-- page=Module:Page
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local String = require('Module:StringUtils')

local page = {}

---Checks if a page exists for a given (internal) link
---@param link string
---@return boolean
function page.exists(link)
	local existingPage = mw.title.new(link)

	-- In some cases we might have gotten an external link,
	-- which will mean `existingPage` will equal nil
	if existingPage == nil then
		return false
	end

	return existingPage.exists
end

---@param options {onlyIfExists: boolean?}
---@param display string?
---@param customLink string?
---@return string?
---@overload fun(display: string?, customLink: string?): string?
function page.makeInternalLink(options, display, customLink)
	-- if no options are passed along (e.g. if the module is invoked from wiki code)
	-- we need to shift the vars around to account for that
	if type(options) == 'string' then
		customLink = display
		display = options
	end
	if String.isEmpty(display) then
		return nil
	elseif String.isEmpty(customLink) then
		customLink = display
	end
	---@cast customLink -nil

	if (options or {}).onlyIfExists == true and (not page.exists(customLink)) then
		return nil
	end

	return '[[' .. customLink .. '|' .. display .. ']]'
end

---@param display string?
---@param link string?
---@return string?
function page.makeExternalLink(display, link)
	if String.isEmpty(display) or String.isEmpty(link) then
		return nil
	end

	return '[' .. link .. ' ' .. display .. ']'
end

return Class.export(page)
