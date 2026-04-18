-- For use with sumneko-lua vscode/neovim extension.
-- This file is automatically read assuming the extension is setup correctly.
-- The setting "Lua.runtime.plugin" needs to be set to "plugins/sumneko_plugin.lua"
-- See more at https://github.com/sumneko/lua-language-server/wiki/Plugin

local importFunctions = {}

---@param  uri  string
---@param  name string # Argument of require()
---@param  source string # The source file uri
---@return string[]?
-- luacheck: push ignore
function ResolveRequire(uri, name, source)
-- luacheck: pop ignore
	local fileName = importFunctions.luaifyModuleName(name)

	-- Extract the base path (up to and including /lua/) and the wiki name from the source URI
	local basePath, wiki = source:match('^(file://.-/lua)/wikis/([^/]+)/')
	if not basePath then
		return nil
	end

	-- Check if the file exists in the same wiki
	local wikiPath = basePath .. '/wikis/' .. wiki .. '/' .. fileName .. '.lua'
	local wikiFile = io.open(wikiPath:gsub('^file://', ''), 'r')
	if wikiFile then
		wikiFile:close()
		return {wikiPath}
	end

	-- Fall back to commons wiki
	local commonsPath = basePath .. '/wikis/commons/' .. fileName .. '.lua'
	local commonsFile = io.open(commonsPath:gsub('^file://', ''), 'r')
	if commonsFile then
		commonsFile:close()
		return {commonsPath}
	end

	return nil
end

---Transforms a MediaWiki module name, e.g. `Module:Array`, into a lua repository name, e.g. `Array`
---@param name string
---@return string
function importFunctions.luaifyModuleName(name)
	local normModuleName = name
		:gsub('Module:', '')-- Remove starting Module:

	return normModuleName
end

return importFunctions
