---
-- @Liquipedia
-- page=Module:Infobox/Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class FactionInfobox: BasicInfobox
local FactionInfobox = Class.new(BasicInfobox)

---@return string
function FactionInfobox:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			subHeader = self:subHeader(args),
			image = args.image,
			imageDefault = args.default,
			imageDark = args.imagedark or args.imagedarkmode,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize or 100,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Faction') .. ' Information'},
		Customizable{
			id = 'release',
			children = {
				Cell{
					name = 'Release Date',
					children = {args.releasedate}
				},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories(args.informationType or 'Factions')
		self:categories(unpack(self:getWikiCategories(args)))
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string?
function FactionInfobox:subHeader(args)
	return args.title
end

---@param args table
---@return string[]
function FactionInfobox:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function FactionInfobox:nameDisplay(args)
	return args.name
end

---@param args table
function FactionInfobox:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		type = 'faction',
		date = args.releasedate,
		extradata = {},
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('faction_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function FactionInfobox:addToLpdb(lpdbData, args)
	return lpdbData
end

return FactionInfobox
