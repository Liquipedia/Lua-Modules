---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local ErrorExt = {}

function ErrorExt.logAndStash(error)
	require('Module:Error/Stash').add(error)
	ErrorExt.log(error)
end

function ErrorExt.log(error)
	mw.log(ErrorExt.makeFullDetails(error))
	mw.log()
end

local function tableOrEmpty(tbl)
	return type(tbl) == 'table' and tbl or {}
end

function ErrorExt.makeFullDetails(error)
	local parts = Array.extend(
		error.header,
		error.message,
		ErrorExt.makeFullStackTrace(error),
		ErrorExt.printExtraProps(error)
	)
	return table.concat(parts, '\n')
end

--[[
Builds a string for fields not covered by the other functions in this module.
Returns nil if there are no extra fields.
]]
function ErrorExt.printExtraProps(error)
	local extraProps = Table.copy(error)
	extraProps.message = nil
	extraProps.header = nil
	extraProps.stacks = nil
	extraProps.originalErrors = nil
	if type(extraProps.childErrors) == 'table' then
		extraProps.childErrors = Array.map(extraProps.childErrors, ErrorExt.makeFullDetails)
	end

	if Table.isNotEmpty(extraProps) then
		return 'Additional properties: \n' .. mw.dumpObject(extraProps)
	else
		return nil
	end
end

function ErrorExt.makeFullStackTrace(error)
	local parts = Array.extend(
		error.stacks,
		Array.flatMap(tableOrEmpty(error.originalErrors), function(originalError)
			return {
				'',
				'Error was thrown while handling:',
				originalError.message,
				ErrorExt.makeFullStackTrace(originalError),
			}
		end)
	)
	return table.concat(parts, '\n')
end

--[[
Variant of Array.map that wraps an error handler around each element
transformation. At the end, the successfully transformed elements are separated
from the errors, and both are returned.
]]
function ErrorExt.mapTry(elems, f)
	local errors = {}
	local results = Array.map(elems, function(elem, index)
		return Logic.try(function() return f(elem, index) end)
			:catch(function(error)
				error.elem = elem
				error.index = index
				table.insert(errors, error)
			end)
			:get()
	end)
	return results, errors
end

return ErrorExt
