-- For use with sumneko-lua vscode/neovim extension.
-- This file is automatically read assuming the extension is setup correctly.
-- The setting "Lua.runtime.plugin" needs to be set to "plugins/sumneko_plugin.lua"
-- See more at https://github.com/sumneko/lua-language-server/wiki/Plugin

local liquipedia = {}

local importFunctions = {}
importFunctions.functions = {'require', 'mw%.loadData', 'Lua%.import', 'Lua%.requireIfExists'}
importFunctions.prefixModules = {
	table = 'standard.',
	math = 'standard.',
	string = 'standard.',
	array = 'standard.',
	match = 'components.match2.commons.',
}

---Transforms a MediaWiki module name, e.g. `Module:Array`, into a lua repository name, e.g. `array`
---@param name string
---@return string
function importFunctions.luaifyModuleName(name)
	local normModuleName = name
		:gsub('Module:', '')-- Remove starting Module:
		:gsub('^%u', string.lower)-- Lower case first letter
		:gsub('%u', '_%0')-- Prefix uppercase letters with an underscore
		:gsub('/', '_')-- Change slash to underscore
		:gsub('__', '_')-- Never have two underscores in a row
		:lower() -- Lowercase everything

	if importFunctions.prefixModules[normModuleName] then
		normModuleName = importFunctions.prefixModules[normModuleName] .. normModuleName
	end

	return normModuleName
end

function importFunctions._row(name)
	local normModuleName = importFunctions.luaifyModuleName(name)

	return ' ---@module \'' .. normModuleName .. '\''
end

function importFunctions.annotate(text, funcName, diffs)
	for module, positionEndOfRow in text:gmatch(funcName .. '%s*%(?%s*[\'"](.-)[\'"]%s*%)?.-()\r?\n') do
		table.insert(diffs,
			{start = positionEndOfRow, finish = positionEndOfRow - 1, text = importFunctions._row(module)}
		)
	end
end

function liquipedia.annotate(text, diffs)
	for _, funcName in pairs(importFunctions.functions) do
		importFunctions.annotate(text, funcName, diffs)
	end
end

---@class diff
---@field start integer # The number of bytes at the beginning of the replacement
---@field finish integer # The number of bytes at the end of the replacement
---@field text string # What to replace

-- luacheck: push ignore
-- setting non-standard global variable 'OnSetText' (but it's mandatory)
---@param uri string # The uri of file
---@param text string # The content of file
---@return nil|diff[]
---@diagnostic disable-next-line: global-element
function OnSetText(uri, text)
-- luacheck: pop ignore
	if text:sub(1, 3) ~= '---' then
		return nil
	end

	if text:sub(1, 8) == '---@meta' then
		return nil
	end

	local diffs = {}

	liquipedia.annotate(text, diffs)

	return diffs
end

return importFunctions
