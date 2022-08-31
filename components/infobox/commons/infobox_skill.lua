---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Skill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local InfoboxBasic = require('Module:Infobox/Basic')
local String = require('Module:StringUtils')
local Namespace = require('Module:Namespace')
local Hotkey = require('Module:Hotkey')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Skill = Class.new(InfoboxBasic)

function Skill.run(frame)
	local skill = Skill(frame)
	return skill:createInfobox()
end

function Skill:createInfobox()
	local infobox = self.infobox
	local args = self.args

	if String.isEmpty(args.informationType) then
		error('You need to specify an informationType, e.g. "Spell", "Ability, ...')
	end

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = args.informationType .. ' Information'},
		Cell{name = 'Caster(s)', content = self:getAllArgsForBase(args, 'caster', { makeLink = true })},
		Customizable{
			id = 'cost',
			children = {
				Cell{
					name = 'Cost',
					content = {args.cost}
				},
			}
		},
		Customizable{
			id = 'hotkey',
			children = {
				Cell{
					name = 'Hotkey',
					content = {self:_getHotkeys(args)}
				},
			}
		},
		Cell{name = 'Range', content = {args.range}},
		Cell{name = 'Radius', content = {args.radius}},
		Customizable{
			id = 'cooldown',
			children = {
				Cell{
					name = 'Cooldown',
					content = {args.cooldown}
				},
			}
		},
		Customizable{
			id = 'duration',
			children = {
				Cell{
					name = 'Duration',
					content = {args.duration}
				},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		local categories = self:getCategories(args)
		infobox:categories(unpack(categories))
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

--- Allows for overriding this functionality
function Skill:getCategories(args)
	return {}
end

function Skill:_getHotkeys(args)
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey2(args.hotkey, args.hotkey2, 'slash')
		else
			display = Hotkey.hotkey(args.hotkey)
		end
	end

	return display
end

return Skill
