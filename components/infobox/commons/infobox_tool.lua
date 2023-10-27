---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Tool
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center

local UNKNOWN = 'Unknown'

---@class ToolInfobox:BasicInfobox
local Tool = Class.new(BasicInfobox)

---Entry point of tool infobox
---@param frame Frame
---@return Html
function Tool.run(frame)
	local tool = Tool(frame)
	return tool:createInfobox()
end

---@return Html
function Tool:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = self.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
		},
		Center{content = {args.caption}},
		Title{name = 'Tool Information'},
		Cell{name = 'Game', content = {
				(args.game or args.defaultGame) .. (args.gameversion and (' ' .. args.gameversion) or '')
		}},
		Cell{name = 'Creator', content = {args.creator or UNKNOWN}},
		Cell{name = 'Current Version', content = {args.version or UNKNOWN}},
		Cell{name = 'Thread', content = {args.thread and ('[' .. args.thread .. ' Thread]') or nil}},
		Cell{name = 'Download', content = {args.download}},
		Center{content = {args.footnotes and ('<small>' .. args.footnotes .. '</small>') or nil}},
	}

	if Namespace.isMain() then
		infobox:categories('Tools', unpack(self:getWikiCategories(args)))
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

--- Allows for overriding this functionality
---Builds the display Name for the header
---@param args table
---@return string
function Tool:getNameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
---Add wikispecific categories
---@param args table
---@return table
function Tool:getWikiCategories(args)
	return {}
end

return Tool
