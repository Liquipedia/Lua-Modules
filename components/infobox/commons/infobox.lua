---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local WidgetFactory = Lua.import('Module:Infobox/Widget/Factory', {requireDevIfEnabled = true})

local Infobox = Class.new()

--- Inits the Infobox instance
function Infobox:create(frame, gameName, forceDarkMode)
	self.frame = frame
	self.root = mw.html.create('div')
	self.adbox = mw.html.create('div')	:addClass('fo-nttax-infobox-adbox')
										:addClass('wiki-bordercolor-light')
										:node(self.frame:preprocess('<adbox />'))
	self.content = mw.html.create('div')	:addClass('fo-nttax-infobox')
											:addClass('wiki-bordercolor-light')
	self.root	:addClass('fo-nttax-infobox-wrapper')
				:addClass('infobox-' .. gameName:lower())
	if forceDarkMode then
		self.root:addClass('infobox-darkmodeforced')
	end

	self.injector = nil
	return self
end

function Infobox:categories(...)
	local input = {...}
	for i = 1, #input do
		local category = input[i]
		if category ~= nil and category ~= '' then
			self.root:wikitext('[[Category:' .. category .. ']]')
		end
	end
	return self
end

function Infobox:widgetInjector(injector)
	self.injector = injector
	return self
end

function Infobox:bottom(wikitext)
	self.bottomContent = wikitext
	return self
end

--- Returns completed infobox
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
