---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Skill
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local InfoboxBasic = require('Module:Infobox/Basic')
local String = require('Module:String')
local Namespace = require('Module:Namespace')
local Hotkey = require('Module:Hotkey')
local PageLink = require('Module:Page')

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
	local hotkeyDescription, hotkeyDisplay = self:getHotkeys(args)
	local durationDescription, durationDisplay = self:getDuration(args)

	local widgets = {
		Header{name = args.name, image = args.image, size = args.imageSize},
		Center{content = {args.caption}},
		Title{name = args.informationType .. ' Information'},
		Cell{name = 'Caster(s)', content = self:getAllArgsForBase(args, 'caster', { makeLink = true })},
		Cell{name = 'Cost', content = {self:getCostDisplay(args)}},
		Cell{name = hotkeyDescription, content = {hotkeyDisplay}},
		Cell{name = 'Range', content = {args.range}},
		Cell{name = 'Radius', content = {args.radius}},
		Cell{
			name = PageLink.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown',
			content = {args.cooldown}
		},
		Cell{name = durationDescription, content = {durationDisplay}},
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

--- Allows for overriding this functionality
function Skill:getDuration(args)
	return 'Duration', args.duration
end

--- Allows for overriding this functionality
function Skill:getHotkeys(args)
	local description = 'Hotkey'
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey(args.hotkey, args.hotkey2, 'slash')
		else
			display = Hotkey.hotkey(args.hotkey)
		end
	end

	return description, display
end

--- Allows for overriding this functionality
function Skill:getCostDisplay(args)
	return args.cost
end

return Skill
