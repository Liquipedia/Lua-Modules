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

local VERSION_DEFINITIVE_EDITION = 'Definitive Edition'

---@class AoePatchInfobox: PatchInfobox
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
		return {
			Cell{name = 'Game', children = {Game.name{game = args.game, useDefault = false}}, options = {makeLink = true}},
			Cell{name = 'Version', children = {args.version}, options = {makeLink = true}},
			Cell{name = 'Expansion Set', children = {args.expansion}, options = {makeLink = true}},
		}
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
	local game = Game.name{game = args.game, useDefault = false} or ''
	local version = args.version or ''
	local prefix = version == VERSION_DEFINITIVE_EDITION and '/Update' or '/Patch'

	---@param input string?
	---@return string?
	local buildChronolgyLink = function(input)
		if Logic.isEmpty(input) then return end
		return game .. '/' .. version
			.. (args.expansion and ('/' .. args.expansion) or '')
			.. prefix .. ' ' .. input .. '|' .. input
	end

	return {
		previous = buildChronolgyLink(args.previous),
		next = buildChronolgyLink(args.next),
	}
end

return CustomPatch
