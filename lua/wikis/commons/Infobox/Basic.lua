---
-- @Liquipedia
-- page=Module:Infobox/Basic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Info = Lua.import('Module:Info')
local Infobox = Lua.import('Module:Widget/Infobox/Core')

---@class BasicInfobox
---@operator call(Frame): BasicInfobox
---@field args table
---@field pagename string
---@field name string
---@field wiki string
---@field injector WidgetInjector?
---@field warnings string[]
---@field bottomContent string[]
local BasicInfobox = Class.new(
	function(self, frame)
		self.args = Arguments.getArgs(frame)
		self.pagename = mw.title.getCurrentTitle().text
		self.name = self.args.name or self.pagename
		self.wiki = self.args.wiki or Info.wikiName
		self.bottomContent = {}
		self.warnings = {}
		self.injector = nil
	end
)

---Adds categories
---@param ... string?
---@return self
function BasicInfobox:categories(...)
	Array.forEach({...}, function(cat) return mw.ext.TeamLiquidIntegration.add_category(cat) end)
	return self
end

---Adds bottom content
---@param content string|number|Html|nil
---@return self
function BasicInfobox:bottom(content)
	table.insert(self.bottomContent, content)
	return self
end

---@param injector WidgetInjector?
---@return self
function BasicInfobox:setWidgetInjector(injector)
	self.injector = injector
	return self
end

--- Allows for overriding this functionality
---Add bottom content below the infobox, e.g. matchtickers
---@return string?
function BasicInfobox:createBottomContent()
	return nil
end

--- Allows for overriding this functionality
---Set wikispecific categories
---@param args table
---@return table
function BasicInfobox:getWikiCategories(args)
	return {}
end

--- Allows for using this for customCells
---Fetches all arguments from the args table for a given base
---@generic K, V
---@param args {[K]: V}
---@param base string
---@param options {makeLink: boolean?}?
---@return V[]
function BasicInfobox:getAllArgsForBase(args, base, options)
	options = options or {}

	local makeLink = Logic.readBool(options.makeLink)
	local foundArgs = {}

	for key, value in Table.iter.pairsByPrefix(args, base, {requireIndex = false}) do
		if makeLink then
			local link = args[key .. 'link'] or value
			value = '[[' .. link .. '|' .. value .. ']]'
		end
		table.insert(foundArgs, value)
	end

	return foundArgs
end

---@param widgets Widget[]
---@return string
function BasicInfobox:build(widgets)
	local infobox = Infobox{
		gameName = self.wiki,
		forceDarkMode = Logic.readBool(self.args.darkmodeforced),
		bottomContent = self.bottomContent,
		warnings = self.warnings,
		children = widgets,
	}
	if self.injector then
		-- Customizable backwards compatibility
		local CustomizableContext = Lua.import('Module:Widget/Contexts/Customizable')
		return CustomizableContext.LegacyCustomizable{value = self.injector, children = {infobox}}:tryMake()
	end
	return infobox:tryMake()
end

return BasicInfobox
