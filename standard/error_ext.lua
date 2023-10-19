---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Ext
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Error = require('Module:Error')
local Json = require('Module:Json')
local Page = require('Module:Page')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local FILTERED_STACK_ITEMS = {
	'Module:ResultOrError:124: in function <Module:ResultOrError:123>',
	'Module:ResultOrError:115: in function <Module:ResultOrError:114>',
	'[C]: in function \'xpcall\'',
	'Module:ResultOrError:113: in function \'try\'',
}

local pageVars = PageVariableNamespace('ErrorStash')

local _local_errors = {}

local ErrorExt = {}

---@param error error
function ErrorExt.logAndStash(error)
	ErrorExt.Stash.add(error)
	ErrorExt.log(error)
end

---@param error error
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

---@param error error
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
---@param error error
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

---@param error error
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

---Builds a JSON string for using with `liquipedia.customLuaErrors` JS module via error().
---@param error error
---@return string
function ErrorExt.printErrorJson(error)
	local stackTrace = {}
	for _, stack in ipairs(error.stacks) do
		local stackFrames = mw.text.split(stack, '\n')
		stackFrames = Array.filter(
			Array.map(
				Array.sub(stackFrames, 2, #stackFrames),
				function(frame) return String.trim(frame) end
			),
			function(frame) return not Table.includes(FILTERED_STACK_ITEMS, frame) end
		)
		for index, frame in ipairs(stackFrames) do
			if not (index == 1 and frame == '[C]: ?') then
				local stackEntry = {content = frame}
				local frameSplit = mw.text.split(frame, ':', true)
				if (frameSplit[1] == '[C]' or frameSplit[1] == '(tail call)') then
					stackEntry.prefix = frameSplit[1]
					stackEntry.content = table.concat(frameSplit, ':', 2)
				elseif frameSplit[1] == 'mw.lua' then
					stackEntry.prefix = table.concat(frameSplit, ':', 1, 2)
					stackEntry.content =  table.concat(frameSplit, ':', 3)
				elseif frameSplit[1] == 'Module' then
					local wiki = not Page.exists(table.concat(frameSplit, ':', 1, 2)) and 'commons'
						or mw.text.split(mw.title.getCurrentTitle():canonicalUrl(), '/', true)[4] or 'commons'
					stackEntry.link = {wiki = wiki, title = table.concat(frameSplit, ':', 1, 2), ln = frameSplit[3]}
					stackEntry.prefix = table.concat(frameSplit, ':', 1, 3)
					stackEntry.content = table.concat(frameSplit, ':', 4)
				end
				table.insert(stackTrace, stackEntry)
			end
		end
	end

	return Json.stringify({
			errorShort = string.format('Lua error in %s:%s at line %s:%s.', unpack(mw.text.split(error.error, ':', true)))
			, stackTrace = stackTrace,
		})
end

local Stash = {}
ErrorExt.Stash = Stash

---Adds an Error instance to the local store.
---@param error error
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
---@return error[]
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
