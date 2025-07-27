---
-- @Liquipedia
-- page=Module:Infobox/Strategy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class StrategyInfobox: BasicInfobox
local Strategy = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Strategy.run(frame)
	local strategy = Strategy(frame)
	return strategy:createInfobox()
end

---@return string
function Strategy:createInfobox()
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
		Center{children = {args.caption}},
		Title{children = args.informationType .. ' Information'},
		Cell{
			name = 'Creator(s)',
			content = {args.creator or args['created-by']},
			options = {makeLink = true}
		},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories('Strategies')
	end

	return self:build(widgets)
end

return Strategy
