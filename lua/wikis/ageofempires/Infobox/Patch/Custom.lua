---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Patch = Lua.import('Module:Infobox/Patch')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local WidgetUtil = Lua.import('Module:Widget/Util')

local VERSION_DEFINITE_EDITION = 'Definitive Edition'
local GAME_AOE2 = 'aoe2'

---@class AoePatchInfobox: PatchInfobox
---@field gameIdentifier string?
---@field gameData GameData?
local CustomPatch = Class.new(Patch)

---@class AoePatchInfoboxWidgetInjector: WidgetInjector
---@field caller AoePatchInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = CustomPatch(frame)
	patch:setWidgetInjector(CustomInjector(patch))
	return patch:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args  = caller.args
	if id == 'version' then
		return WidgetUtil.collect(
			Cell{name = 'Game', children = {Game.name{game = args.game, useDefault = false}}, options = {makeLink = true}},
			Cell{name = 'Version', children = {args.version}},
			Cell{name = 'Expansion Set', children = {args.expansion}, options = {makeLink = true}}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomPatch:getWikiCategories(args)
	local game = Game.name{game = args.game, useDefault = false}
	return {
		game and ('Updates (' .. game .. ')') or nil
	}
end

---Adjust Lpdb data
---@param lpdbData table
---@param args table
---@return table
function CustomPatch:addToLpdb(lpdbData, args)
	Table.mergeInto(lpdbData.extradata, {
		game = Game.name{game = args.game, useDefault = false},
		version = args.version, -- todo: check usage and eliminate in follow up
		patchversion = args.patch_version, -- yes this is only stored but not displayed
	})
	return lpdbData
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local game = Game.name{game = args.game, useDefault = false}
	local version = args.version or ''

	---@param input string?
	---@return string?
	local buildChronolgyLink = function(input)
		if Logic.isEmpty(input) then
			return
		elseif version ~= VERSION_DEFINITE_EDITION then
			return (game or '') .. version .. '/Patch ' .. input .. '|' .. version
		end
		return (game or Game.name{game = GAME_AOE2}) .. '/' .. version
			.. (args.expansion and ('/' .. args.expansion) or '')
			.. '/Update ' .. input .. '|' .. input
	end

	return {
		previous = buildChronolgyLink(args.previous),
		next = buildChronolgyLink(args.next),
	}
end

return CustomPatch
