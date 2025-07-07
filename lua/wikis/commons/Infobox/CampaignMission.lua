---
-- @Liquipedia
-- page=Module:Infobox/CampaignMission
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Breakdown = Widgets.Breakdown

---@class CampaignMissionInfobox: BasicInfobox
local Mission = Class.new(BasicInfobox)

---Entry point
---@param frame Frame
---@return Html
function Mission.run(frame)
	local mission = Mission(frame)
	return mission:createInfobox()
end

---@return string
function Mission:createInfobox()
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
		Center{children = {args.caption}},
		Title{children = 'Mission Information'},
		Breakdown{
			children = {'Mission Objective'},
			classes = {'infobox-header', 'wiki-backgroundcolor-light', 'infobox-header-3'}
		},
		Breakdown{children = { args.objective }},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories('Missions', 'Campaign')
		self:categories(unpack(self:getWikiCategories(args)))
	end

	return self:build(widgets)
end

return Mission
