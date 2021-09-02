---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Scene
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Localisation = require('Module:Localisation')
local Flags = require('Module:Flags')
local Links = require('Module:Links')
local InfoboxBasic = require('Module:Infobox/Basic')
local String = require('Module:String')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

local Scene = Class.new(InfoboxBasic)

function Scene.run(frame)
	local scene = Scene(frame)
	return scene:createInfobox()
end

function Scene:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = ({
		Header({name = self:createNameDisplay(args), image = args.image}),
		Center(args.caption),
		Title('Scene Information'),
		Cell({name = 'National team', content = {args.nationalteam}, options = {makeLink = true}}),
		Cell({name = 'Events', content = self:getAllArgsForBase(args, 'event', {makeLink = true})}),
		Cell({name = 'Size', content = {args.size}}),
		Customizable('custom', {}),
	})

	local links = Links.transform(args)
	table.insert(widgets, Center(args.footnotes))
	if not Table.isEmpty(links) then
		table.insert(widgets, Title('Links'))
		table.insert(widgets, Widgets.Links(links))
	end

	if not String.isEmpty(args.achievements) then
		table.insert(widgets, Title('Achievements'))
		table.insert(widgets, Center(args.achievements))
	end

	infobox:categories('Scene')

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

--- Allows for overriding this functionality
function Scene:createNameDisplay(args)
	local name = args.name
	local country = Flags._CountryName(args.country or args.scene)
	if not name then
		local localised = Localisation.getLocalisation(country)
		local flag = Flags._Flag(country)
		name = flag .. '&nbsp;' .. localised .. ((' ' .. args.gamenamedisplay) or '') .. ' scene'
	end

	Variables.varDefine('country', country)

	return name
end

return Scene
