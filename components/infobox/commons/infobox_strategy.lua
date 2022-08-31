---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Strategy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local BasicInfobox = require('Module:Infobox/Basic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Strategy = Class.new(BasicInfobox)

function Strategy.run(frame)
	local strategy = Strategy(frame)
	return strategy:createInfobox()
end

function Strategy:createInfobox()
	local infobox = self.infobox
	local args = self.args

	if String.isEmpty(args.informationType) then
		error('You need to specify an informationType, e.g. "Strategy", "Technique, ...')
	end

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
		Title{name = args.informationType .. ' Information'},
		Cell{
			name = 'Creator(s)',
			content = {args.creator or args['created-by']},
			options = {makeLink = true}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Strategies')
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

return Strategy
