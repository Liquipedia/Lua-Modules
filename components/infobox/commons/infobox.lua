---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory', {requireDevIfEnabled = true})

---@class Infobox
---@field frame Frame
---@field root Html
---@field adbox Html
---@field content Html
---@field injector WidgetInjector
local Infobox = Class.new()

--- Inits the Infobox instance
---@param frame Frame
---@param gameName string
---@param forceDarkMode boolean?
---@return Infobox
function Infobox:create(frame, gameName, forceDarkMode)
	self.frame = frame
	self.root = mw.html.create('div')
	self.adbox = mw.html.create('div')	:addClass('fo-nttax-infobox-adbox')
										:node(self.frame:preprocess('<adbox />'))
	self.content = mw.html.create('div')	:addClass('fo-nttax-infobox')
	self.root	:addClass('fo-nttax-infobox-wrapper')
				:addClass('infobox-' .. gameName:lower())
	if forceDarkMode then
		self.root:addClass('infobox-darkmodeforced')
	end

	self.injector = nil
	return self
end

---Adds categories
---@param ... string?
---@return Infobox
function Infobox:categories(...)
	Array.forEach({...}, function(cat) return mw.ext.TeamLiquidIntegration.add_category(cat) end)
	return self
end

---Sets the widgetInjector
---@param injector any
---@return Infobox
function Infobox:widgetInjector(injector)
	self.injector = injector
	return self
end

---Adds a custom widgets to the bottom of the infobox
---@param wikitext string|number|Html|nil
---@return Infobox
function Infobox:bottom(wikitext)
	self.bottomContent = wikitext
	return self
end

--- Returns completed infobox
---@param widgets Widget[]
---@return Html?
function Infobox:build(widgets)
	for _, widget in ipairs(widgets) do
		if widget == nil or widget['is_a'] == nil then
			return error('Infobox:build can only accept Widgets')
		end
		widget:setContext({injector = self.injector})

		local contentItems = WidgetFactory.work(widget, self.injector)

		for _, node in ipairs(contentItems or {}) do
			self.content:node(node)
		end
	end

	self.root:node(self.content)

	local isFirstInfobox = Variables.varDefault('is_first_infobox', true)
	if isFirstInfobox == true then
		self.root:node(self.adbox)
		Variables.varDefine('is_first_infobox', 'false')
	end
	if self.bottomContent ~= nil then
		self.root:node(self.bottomContent)
	end

	return self.root
end

return Infobox
