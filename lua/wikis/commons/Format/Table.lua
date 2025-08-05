---
-- @Liquipedia
-- page=Module:Format/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local TableFormatter = {}

---Converts a lua table to html display of the table for easy copy paste
---@param inputTable table
---@param options {asText: boolean?}?
---@return Html|string
function TableFormatter.toLuaCode(inputTable, options)
	if type(inputTable) ~= 'table' then
		error('TableFormatter.toLuaCode needs a table as input')
	end

	local asText = (options or {}).asText

	if Table.isEmpty(inputTable) then
		return asText and '' or mw.html.create('pre')
			:addClass('selectall')
			:wikitext('{}')
	end

	local function escapeSingleQuote(str)
		return str:gsub('\'', '\\\'')
	end

	local function displayValue(value)
		if type(value) == 'string' then
			return '\'' .. mw.text.nowiki(escapeSingleQuote(value)) .. '\''
		else
			return tostring(value)
		end
	end

	local function order(_, key1, key2)
		-- cases due to possibly having numbers and strings as keys
		if Logic.isNumeric(key1) and Logic.isNumeric(key2) then
			return key1 < key2
		elseif Logic.isNumeric(key1) then
			return true
		elseif Logic.isNumeric(key2) then
			return false
		else -- 2 strings
			return key1 < key2
		end
	end

	local function toLuaString(tbl, indentNumber)
		local luaString = '{'

		for index, obj in ipairs(tbl) do
			luaString = luaString .. '\n' .. string.rep('\t', indentNumber)
			-- value display
			if type(obj) == 'table' then
				luaString = luaString .. toLuaString(obj, indentNumber + 1)
			else
				luaString = luaString .. displayValue(obj)
			end
			luaString = luaString .. ','
			tbl[index] = nil
		end

		for key, obj in Table.iter.spairs(tbl, order) do
			luaString = luaString .. '\n' .. string.rep('\t', indentNumber)
			--key display
			if type(key) == 'number' then
				luaString = luaString .. '[' .. key .. '] = '
			else
				luaString = luaString .. '[\'' .. escapeSingleQuote(key) .. '\'] = '
			end

			-- value display
			if type(obj) == 'table' then
				luaString = luaString .. toLuaString(obj, indentNumber + 1)
			else
				luaString = luaString .. displayValue(obj)
			end
			luaString = luaString .. ','
		end

		return luaString .. '\n' .. string.rep('\t', indentNumber - 1) .. '}'
	end

	if asText then
		return toLuaString(inputTable, 1)
	end

	return mw.html.create('pre')
		:addClass('selectall')
		:wikitext(toLuaString(inputTable, 1))
end

return TableFormatter
