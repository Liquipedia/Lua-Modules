---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Stash
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Error = require('Module:Error')
local Json = require('Module:Json')
local PageVariableNamespace = require('Module:PageVariableNamespace')

local pageVars = PageVariableNamespace('ErrorStash')

local localErrors = {}
local deferred = false

--[[
A place to temporarily store errors so they can be displayed later. The errors
must be error instances, not strings or primitives.
]]
local ErrorStash = {}

--[[
Adds an Error instance to the local store.

If the current entry point has been marked to not display errors, then this
will store the error to page variables instead.
]]
function ErrorStash.add(error)
	if deferred then
		local count = tonumber(pageVars:get('count')) or 0
		pageVars:set('count', count + 1)
		pageVars:set(count + 1, Json.stringify({error}))
	else
		table.insert(localErrors, error)
	end
end

--[[
Returns all errors (locally and from page variables), and clears the store.

If the current entry point has been marked to not display errors, then this
returns the empty array and does nothing.
]]
function ErrorStash.retrieve()
	if deferred then return {} end

	local errors = {}

	local count = tonumber(pageVars:get('count')) or 0
	pageVars:delete('count')
	for i = 1, count do
		Array.extendWith(errors, Array.map(Json.parse(pageVars:get(i)), Error))
		pageVars:delete(i)
	end

	Array.extendWith(errors, localErrors)
	localErrors = {}

	return errors
end

--[[
Moves all local errors to page variables, and signals that the current entry
point should not display errors.

This should be called by entry points that do not return wikicode. For entry
points that are invoked with Lua.invoke (or equivalent), this can be called at
any time. For others, this should be called near the end of lua execution, so
that all errors are caught.
]]
function ErrorStash.deferDisplay()
	if #localErrors > 0 then
		local count = tonumber(pageVars:get('count')) or 0
		pageVars:set('count', count + 1)
		pageVars:set(count + 1, Json.stringify(localErrors))
	end

	localErrors = {}
	deferred = true
end

return ErrorStash
