-- For use with sumneko-lua vscode/neovim extension.
-- This file is automatically read assuming the extension is setup correctly.
-- The setting "Lua.runtime.plugin" needs to be set to "plugins/sumneko_plugin.lua"
-- See more at https://github.com/sumneko/lua-language-server/wiki/Plugin

local importFunctions = {}

local IS_WINDOWS = package.config:sub(1,1) ~= '/'

---@param repoRoot string # Documentation of this parameter is unclear. Seems to be repo root
---@param name string # Argument of require()
---@param source string # The source file uri
---@return string[]?
-- luacheck: push ignore
function ResolveRequire(repoRoot, name, source)
-- luacheck: pop
	local fileName = importFunctions.luaifyModuleName(name)

	-- Extract the base path (up to and including /lua/) from the source URI.
	-- Also try to extract the wiki name when the source is under /wikis/<wiki>/.
	-- Files outside of /wikis/ (e.g. spec/, definitions/) default to commons.
	local basePath = source:match('^(file://.-/lua)[/$]')
	if not basePath then
		return nil
	end

	if IS_WINDOWS then
		-- On Windows, the file URI starts with file:///C:/path/to/repo, so we need to remove the extra slash
		-- Also need to unescape the :, otherwise %3 would be treated as a capture group result in later patterns
		basePath = basePath:gsub('^file:///', 'file://'):gsub('%%3A', ':')
	end
	-- See the unescaping of : above
	basePath = basePath:gsub('%20', ' ')

	local wiki = source:match('^file://.-/lua/wikis/([^/]+)/') or 'commons'

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
