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

function page.exists(link)
	local existingPage = mw.title.new(link)

	-- In some cases we might have gotten an external link,
	-- which will mean `existingPage` will equal nil
	if existingPage == nil then
		return false
	end

	return existingPage.exists
end

function page.makeInternalLink(link, display)
	if String.isEmpty(link) then
		return nil
	elseif String.isEmpty(display) then
		display = link
	end

	return '[[' .. link .. '|' .. display .. ']]'
end

function page.makeInternalLinkIfExists(link, display)
	if String.isEmpty(link) then
		return nil
	elseif String.isEmpty(display) then
		display = link
	end
	if not page.exists(link) then
		return nil
	end

	return '[[' .. link .. '|' .. display .. ']]'
end

function page.makeExternalLink(link, display)
	if String.isEmpty(link) then
		return nil
	end
	local output = '[' .. link
	if not String.isEmpty(display) then
		output = output .. ' ' .. display
	end

	return output .. ']'
end

return Class.export(page)
