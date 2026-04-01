---
-- @Liquipedia
-- page=Module:Error/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Error = require('Module:Error')
local Json = require('Module:Json')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local Table = require('Module:Table')

local pageVars = PageVariableNamespace('ErrorStash')

local _local_errors = {}

local ErrorExt = {}

---@param error Error
function ErrorExt.logAndStash(error)
	ErrorExt.Stash.add(error)
	ErrorExt.log(error)
end

---@param error Error
function ErrorExt.log(error)
	mw.log(ErrorExt.makeFullDetails(error))
	mw.log()
end

---@param tbl table
---@return table
---@overload fun(tbl: any): {}
local function tableOrEmpty(tbl)
	return type(tbl) == 'table' and tbl or {}
end

---@param error Error
---@return string
function ErrorExt.makeFullDetails(error)
	local parts = Array.extend(
		error.header,
		error.message,
		ErrorExt.makeFullStackTrace(error),
		ErrorExt.printExtraProps(error)
	)
	return table.concat(parts, '\n')
end

---Builds a string for fields not covered by the other functions in this module.
---Returns nil if there are no extra fields.
---@param error Error
---@return string?
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

---@param error Error
---@return string
function ErrorExt.makeFullStackTrace(error)
	local parts = Array.extend(
		error.stacks,
		Array.flatten(Array.map(tableOrEmpty(error.originalErrors), function(originalError)
			return {
				'',
				'Error was thrown while handling:',
				originalError.message,
				ErrorExt.makeFullStackTrace(originalError),
			}
		end))
	)
	return table.concat(parts, '\n')
end

local Stash = {}
ErrorExt.Stash = Stash

---Adds an Error instance to the local store.
---@param error Error
---@param storeAsPageVar boolean?
function Stash.add(error, storeAsPageVar)
	if storeAsPageVar then
		local count = tonumber(pageVars:get('count')) or 0
		pageVars:set('count', count + 1)
		pageVars:set(count + 1, Json.stringify{error})
	else
		table.insert(_local_errors, error)
	end
end

---Returns all errors (locally and from page variables), and clears the store.
---@return Error[]
function Stash.retrieve()
	local errors = {}

	local count = tonumber(pageVars:get('count')) or 0
	pageVars:delete('count')
	for i = 1, count do
		Array.extendWith(errors, Array.map(Json.parse(pageVars:get(i)), Error))
		pageVars:delete(i)
	end

	Array.extendWith(errors, _local_errors)
	_local_errors = {}

	return errors
end

return ErrorExt
