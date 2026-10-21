---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Components/Tabs
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Builds the tab arguments for the Tabs widget from the hardcoded profile tab lists.

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Variables = Lua.import('Module:Variables')

local QueryLink = Lua.import('Module:Widget/QueryLink')

local ProfileTabsApiMatches = Lua.import('Module:Features/ProfileTabs/Api/Matches')
local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsTabs = {}

---Checks whether profile tab content can be shown (Results subpage or lpdb matches).
---@param profileType string
---@param profile string
---@return boolean
local function hasResultsData(profileType, profile)
	return Page.exists(profile .. '/Results') or ProfileTabsApiMatches.has(profileType, profile)
end

---Reads a boolean flag from the template args first, falling back to the wiki variable.
---@param args table?
---@param name string
---@return boolean
local function readFlag(args, name)
	local argValue = args and args[name]
	return Logic.readBool(argValue == nil and Variables.varDefault(name) or argValue)
end

---Builds a QueryLink widget for a query form tab.
---@param query table
---@param display string
---@param profile string
---@return Renderable
local function buildQueryLink(query, display, profile)
	return QueryLink{
		mediawikiForm = query.mediawikiForm,
		form = query.form,
		template = query.template,
		display = display,
		queryArgs = {[query.queryArg] = profile},
	}
end

---Builds the tab configuration for profile tabs (Overview always, rest only when their page exists).
---@param profileType string
---@param profile string
---@param args table?
---@return table<string, string|Renderable> A
function ProfileTabsTabs.getTabArgs(profileType, profile, args)
	local settings = PROFILE_TYPES[profileType]
	local hasResults = hasResultsData(profileType, profile)

	---@type table<string, string|Renderable>
	local tabArgs = {name1 = 'Overview', link1 = profile}
	local tabCounter = 1

	local useTabsToForms = readFlag(args, 'tabsToForms')

	Array.forEach(settings.tabs, function(tabName)
		-- Replaces the plain subpage tab with a QueryLink in its slot.
		local tabToForm = useTabsToForms and hasResults
			and settings.tabsToForms and settings.tabsToForms[tabName]
		if tabToForm then
			tabCounter = tabCounter + 1
			tabArgs['name' .. tabCounter] = buildQueryLink(tabToForm, tabToForm.display, profile)
			return
		end

		local showTab = Page.exists(profile .. '/' .. tabName)
		if showTab then
			tabCounter = tabCounter + 1
			local displayName = settings.tabDisplay and settings.tabDisplay[tabName] or tabName
			tabArgs['name' .. tabCounter] = displayName
			tabArgs['link' .. tabCounter] = profile .. '/' .. tabName
		end
end)

	if (readFlag(args, 'h2h') and hasResults) then
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = buildQueryLink(settings.headToHead, 'Head to head', profile)
	end

	if (readFlag(args, 'statistics') and settings.statistics and hasResults) then
		tabCounter = tabCounter + 1
		tabArgs['name' .. tabCounter] = buildQueryLink(settings.statistics, 'Statistics', profile)
	end

	return tabArgs
end

return ProfileTabsTabs
