---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Scene
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Links = require('Module:Links')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder

---@class SceneInfobox: BasicInfobox
local Scene = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Scene.run(frame)
	local scene = Scene(frame)
	return scene:createInfobox()
end

---@return string
function Scene:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = self:createNameDisplay(args),
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Scene Information'},
		Cell{name = 'Region', content = {args.region}},
		Cell{name = 'National Team', content = {args.nationalteam}, options = {makeLink = true}},
		Cell{name = 'Events', content = self:getAllArgsForBase(args, 'event', {makeLink = true})},
		Cell{name = 'Size', content = {args.size}},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
		Builder{
			builder = function()
				local links = Links.transform(args)
				if not Table.isEmpty(links) then
					return {
						Title{name = 'Links'},
						Widgets.Links{content = links}
					}
				end
			end
		},
		Builder{
			builder = function()
				if not String.isEmpty(args.achievements) then
					return {
						Title{name ='Achievements'},
						Center{content = {args.achievements}}
					}
				end
			end
		}
	}

	self:categories('Scene')

	return self:build(widgets)
end

--- Allows for overriding this functionality
---@param args table
---@return string
function Scene:createNameDisplay(args)
	local name = args.name
	local country = Flags.CountryName(args.country or args.scene)
	if not name then
		local localised, errorText = Flags.getLocalisation(country)
		local flag = Flags.Icon({flag = country, shouldLink = true})
		name = flag .. '&nbsp;' .. (localised or errorText) .. ((' ' .. args.gamenamedisplay) or '') .. ' scene'
	end

	Variables.varDefine('country', country)

	return name
end

return Scene
