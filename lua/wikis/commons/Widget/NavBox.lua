---
-- @Liquipedia
-- page=Module:Widget/NavBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local NavBoxTitle = Lua.import('Module:Widget/NavBox/Title')
local Widget = Lua.import('Module:Widget')

local NavBoxChild = Lua.import('Module:Widget/NavBox/Child')

---- technically from wiki input they will be all string representations
---@class NavBoxProps: NavBoxChildProps
---@field isChild boolean? # from wiki input string?
---@field child1 string|NavBoxChildProps
---@field title string
---@field hideonmobile boolean? # from wiki input string?
---@field template string?

---@class NavBox: Widget
---@operator call(table): NavBox
---@field props NavBoxProps
local NavBox = Class.new(Widget)

---@return Widget
function NavBox:render()
	local props = self.props

	-- if the NavBox is used as a child in another NavBox return the props as Json
	if Logic.readBool(props.isChild) then
		return Json.stringify(props)
	end

	assert(props.child1, 'No children inputted')

	local shouldCollapse = self:_determineCollapsedState(Table.extract(props, 'collapsed'))

	local title = NavBoxTitle(Table.merge(props, {isWrapper = true}))
	-- have to extract so the child doesn't add the header too ...
	local titleInput = Table.extract(props, 'title')
	assert(titleInput, 'Missing "|title="')

	return Collapsible{
		attributes = {
			['aria-labelledby'] = titleInput:gsub(' ', '_'),
			role = 'navigation',
			['data-nosnippet'] = 0,
		},
		classes = {
			'navigation-not-searchable',
			'navbox',
			Logic.readBool(props.hideonmobile) and 'mobile-hide' or nil
		},
		shouldCollapse = shouldCollapse,
		titleWidget = title,
		children = {NavBoxChild(props)},
	}
end

---@private
---@param collapsedInput string|boolean?
---@return boolean
function NavBox:_determineCollapsedState(collapsedInput)
	collapsedInput = Logic.readBoolOrNil(collapsedInput)

	-- case manually inputted true
	if collapsedInput then
		return collapsedInput
	end

	-- as a first step collapse at the top and uncollapse at the bottom
	-- as heuristic assume we are at the bottom if an infobox or HDB is above
	local uncollapseHeuristic = Variables.varDefault('has_infobox') -- any page with an infobox
		or Variables.varDefault('tournament_parent') -- any Page with a HDB

	-- case heuristic says to uncollapse and manual input doesn't say to collapse
	if uncollapseHeuristic then
		return false
	end
	if collapsedInput ~= false then
		return true
	end

	return (Namespace.isMain() or Namespace.isUser())
		and NavBox._getNumberOfChildren(self.props) > 3
end

---@private
---@param props table
---@return integer
function NavBox._getNumberOfChildren(props)
	local numberOfChildren = 0
	if props[1] or Logic.readBool(props.allowEmpty) then
		numberOfChildren = numberOfChildren + 1
	end

	---@type table[]
	local currentChildren = Array.mapIndexes(function(rowIndex) return Json.parseIfTable(props['child' .. rowIndex]) end)

	Array.forEach(currentChildren, function(childProps)
		-- if the child is collapsed do not consider subchildren anymore
		if Logic.readBool(childProps.collapsed) then
			numberOfChildren = numberOfChildren + 1
			return
		end
		numberOfChildren = numberOfChildren + NavBox._getNumberOfChildren(childProps)
	end)

	return numberOfChildren
end

return NavBox
