---
-- @Liquipedia
-- page=Module:Infobox/Upgrade
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Namespace = Lua.import('Module:Namespace')
local Table = Lua.import('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Links = Lua.import('Module:Links')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology

---@class UpgradeInfobox: BasicInfobox
local Upgrade = Class.new(BasicInfobox)

---@return string
function Upgrade:createInfobox()
	local args = self.args
	local links = Links.transform(args)

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Upgrade') .. ' Information'},
		Customizable{
			id = 'introduced',
			children = {
				Cell{name = 'First introduced', children = {args.introduced}},
			},
		},
		Customizable{
			id = 'research',
			children = {
				Cell{name = 'Researched from', children = {args.researchedfrom}, options = {makeLink = true}},
			},
		},
		Customizable{
			id = 'cost',
			children = {
				Cell{name = 'Cost', children = {args.cost}},
			},
		},
		Cell{name = 'Required', children = {args.required}},
		Cell{name = 'Required for', children = self:getAllArgsForBase(args, 'requiredfor'), options = {makeLink = true}},
		Customizable{
			id = 'effect',
			children = {
				Cell{name = 'Effect', children = {args.effect}},
			},
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				if not Table.isEmpty(links) then
					return {
						Title{children = 'Links'},
						Widgets.Links{links = links}
					}
				end
			end
		},
		Center{children = {args.footnotes}},
		Customizable{id = 'chronology', children = {
			Chronology{
				title = self:chronologyTitle(),
				links = Table.filterByKey(args, function(key)
					return type(key) == 'string' and (key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
				end)
			}
		}},
	}

	if Namespace.isMain() then
		self:categories(unpack(self:getWikiCategories(args)))
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

--- Allows for overriding this functionality
---@param args table
function Upgrade:setLpdbData(args)
end

---@return string
function Upgrade:chronologyTitle()
	return 'Chronology'
end

return Upgrade