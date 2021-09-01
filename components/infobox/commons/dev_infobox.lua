---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/dev
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Customizable = require('Module:Infobox/Widget/Customizable')

local Infobox = Class.new()

--- Inits the Infobox instance
function Infobox:create(frame, gameName)
    self.frame = frame
    self.root = mw.html.create('div')
    self.adbox = mw.html.create('div')  :addClass('fo-nttax-infobox-adbox')
                                        :addClass('wiki-bordercolor-light')
                                        :node(self.frame:preprocess('<adbox />'))
    self.content = mw.html.create('div')    :addClass('fo-nttax-infobox')
                                            :addClass('wiki-bordercolor-light')
    self.root   :addClass('fo-nttax-infobox-wrapper')
                :addClass('infobox-' .. gameName)

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

--- Returns completed infobox
function Infobox:build(widgets)
	for _, widget in pairs(widgets) do
		if widget['is_a'] == nil then
			return error('Infobox:build can only accept Widgets')
		end

		if widget:is_a(Customizable) then
			widget:setWidgetInjector(self.injector)
		end

		local contentItems = widget:make()
		for _, node in pairs(contentItems) do
			self.content:node(node)
		end

	end

    self.root:node(self.content)

    self.root:node(self.adbox)
    return self.root
end

return Infobox
