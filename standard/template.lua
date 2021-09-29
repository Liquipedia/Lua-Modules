---
-- @Liquipedia
-- wiki=commons
-- page=Module:Template
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---
-- @author Vogan for Liquipedia
--

local Template = {}

function Template.safeExpand(frame, title, args, defaultTemplate)
	--local start = os.clock()
	local result, value = pcall(frame.expandTemplate, frame, {title = title, args = args})
	if result then
		--mw.log('Module:Template title=' .. title)
		--mw.log('Module:Template:safeExpand_end: ' .. (os.clock() - start))
		return value
	else
		--mw.log('Module:Template title=' .. title)
		--mw.log('Module:Template:safeExpand_end_failed: ' .. (os.clock() - start))
		return defaultTemplate or '[[Template:' .. title .. ']]'
	end
end

function Template.expandTemplate(frame, title, args)
	return frame:expandTemplate {title = title, args = args}
end

return Template
