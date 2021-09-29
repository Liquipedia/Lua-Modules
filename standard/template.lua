---
-- @Liquipedia
-- wiki=commons
-- page=Module:Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Template = {}

function Template.safeExpand(frame, title, args, defaultTemplate)
	local result, value = pcall(frame.expandTemplate, frame, {title = title, args = args})
	if result then
		return value
	else
		local templateName = '[[Template:' .. (title or '') .. ']]'
		return defaultTemplate or templateName
	end
end

function Template.expandTemplate(frame, title, args)
	return frame:expandTemplate {title = title, args = args}
end

return Template
