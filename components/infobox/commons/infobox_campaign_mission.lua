---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/CampaignMission
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local BasicInfobox = require('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Breakdown = Widgets.Breakdown

local Mission = Class.new(BasicInfobox)

function Mission.run(frame)
	local mission = Mission(frame)
	return mission:createInfobox()
end

function Mission:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Customizable{id = 'header', children = {
				Header{
					name = args.name,
					image = args.image,
					imageDark = args.imagedark or args.imagedarkmode,
					size = args.imagesize,
				},
			}
		},
		Center{content = {args.caption}},
		Title{name = 'Mission Information'},
		Breakdown{
			content = {'Mission Objective'},
			classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-3'}
		},
		Breakdown{content = { args.objective }},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Missions', 'Campaign')
		infobox:categories(unpack(self:getWikiCategories(args)))
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

return Mission
