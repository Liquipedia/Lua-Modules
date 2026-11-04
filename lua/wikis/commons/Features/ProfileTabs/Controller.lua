---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Controller
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
-- Orchestration: resolves the profile type, derives the display title and renders the tabs.

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Tabs = Lua.import('Module:Tabs')

local ProfileTabsApiDisplayTitle = Lua.import('Module:Features/ProfileTabs/Api/DisplayTitle')
local ProfileTabsComponentsTabs = Lua.import('Module:Features/ProfileTabs/Components/Tabs')
local PROFILE_TYPES = Lua.import('Module:Features/ProfileTabs/Types')

local ProfileTabsController = {}

---Resolves the profile type from the `target` arg.
---@private
---@param args table
---@return string
function ProfileTabsController._resolveProfileType(args)
	return PROFILE_TYPES[args.target] and args.target or 'player'
end

---Returns the subpage tab name `pageName` belongs to, or nil when on the profile main page.
---@private
---@param profileType string
---@param pageName string
---@return string?
function ProfileTabsController._getSubpageName(profileType, pageName)
	for _, tabName in ipairs(PROFILE_TYPES[profileType].tabs) do
		if pageName:sub(-#tabName - 1) == '/' .. tabName then
			return tabName
		end
	end
end

---Builds the display title for profile pages.
---@private
---@param profileType string
---@param profile string
---@param subpageName string?
---@return string?
function ProfileTabsController._getDisplayTitle(profileType, profile, subpageName)
	if not subpageName then
		return
	end

	local title = ProfileTabsApiDisplayTitle.get(profileType, profile) or profile
	return title .. ': ' .. subpageName
end

---@param frame Frame
---@return Renderable?
function ProfileTabsController.run(frame)
	local args = Arguments.getArgs(frame)
	local profileType = ProfileTabsController._resolveProfileType(args)

	local pageName = mw.title.getCurrentTitle().prefixedText

	local subpageName = ProfileTabsController._getSubpageName(profileType, pageName)
	local profile = subpageName and pageName:sub(1, -#subpageName - 2) or pageName

	local displayTitle
	if args.displayTitle == nil then
		displayTitle = ProfileTabsController._getDisplayTitle(profileType, profile, subpageName)
	elseif Logic.readBoolOrNil(args.displayTitle) ~= false then
		displayTitle = args.displayTitle
	end

	Page.setDisplayTitle{
		title = displayTitle,
	}

	return Tabs.static(ProfileTabsComponentsTabs.getTabArgs(profileType, profile, args))
end

return ProfileTabsController
