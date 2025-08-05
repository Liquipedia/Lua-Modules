---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Patch = Lua.import('Module:Infobox/Patch')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class R6PatchInfobox: PatchInfobox
local CustomPatch = Class.new(Patch)
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
	local args = self.caller.args
	if id == 'release' then
		return {
			Cell{name = 'Release Date', content = {args.release}},
			Cell{name = 'PC Release Date', content = {args.pcrelease}},
			Cell{name = 'Console Release Date', content = {args.consolerelease}},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPatch:addToLpdb(lpdbData, args)
	lpdbData.extradata.version = args.version
	lpdbData.extradata.game = args.game

	return lpdbData
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous then
		data.previous = args.previous .. ' Patch|' .. args.previous
	end
	if args.next then
		data.next = args.next .. ' Patch|' .. args.next
	end
	return data
end

return CustomPatch
