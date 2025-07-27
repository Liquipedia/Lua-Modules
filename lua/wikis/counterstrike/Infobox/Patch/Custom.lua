---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Game = Lua.import('Module:Game')
local Patch = Lua.import('Module:Infobox/Patch')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CounterStrikePatchInfobox: PatchInfobox
---@field gameIdentifier string?
---@field gameData GameData?
local CustomPatch = Class.new(Patch)

---@class CounterStrikePatchInfoboxWidgetInjector: WidgetInjector
---@field caller CounterStrikePatchInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = CustomPatch(frame)
	patch.gameIdentifier = Game.toIdentifier{game = patch.args.game, useDefault = false}
	patch.wiki = patch.gameIdentifier or 'csgo'
	patch.gameData = Game.raw{game = patch.gameIdentifier, useDefault = false}
	patch:setWidgetInjector(CustomInjector(patch))
	return patch:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'custom' then
		return WidgetUtil.collect(
			self.caller:_createGameCell()
		)
	end

	return widgets
end

---@return Widget?
function CustomPatch:_createGameCell()
	if Table.isEmpty(self.gameData) then
		return nil
	end

	return Cell{
		name = 'Game',
		content = {
			IconImageWidget{
				imageLight = self.gameData.logo.lightMode,
				imageDark = self.gameData.logo.darkMode,
				link = self.gameData.link
			},
			Link{
				link = self.gameData.link,
				children = { self.gameData.name }
			}
		},
		options = { separator = ' ' }
	}
end

---Adjust Lpdb data
---@param lpdbData table
---@param args table
---@return table
function CustomPatch:addToLpdb(lpdbData, args)
	lpdbData.extradata.game = self.gameIdentifier
	return lpdbData
end

---@param args table
---@return string[]
function CustomPatch:getWikiCategories(args)
	if Table.isEmpty(self.gameData) then return {} end
	return {self.gameData.abbreviation .. ' Patch'}
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous then
		data.previous = (args['previous link'] or args.previous .. ' Patch') .. '|' .. args.previous
	end
	if args.next then
		data.next = (args['next link'] or args.next .. ' Patch') .. '|' .. args.next
	end
	return data
end

return CustomPatch
