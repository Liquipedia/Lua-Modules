---
-- @Liquipedia
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Infobox/Patch')
local Injector = Lua.import('Module:Widget/Injector')
local Widgets = require('Module:Widget/All')

---@class Dota2PatchInfobox: PatchInfobox
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
	if id == 'custom' then
		return {
			Widgets.Cell{name = 'New Heroes', content = {args.new}},
			Widgets.Cell{name = 'Nerfed Heroes', content = {args.nerfed}},
			Widgets.Cell{name = 'Buffed Heroes', content = {args.buffed}},
			Widgets.Cell{name = 'Rebalanced Heroes', content = {args.rebalanced}},
			Widgets.Cell{name = 'Reworked Heroes', content = {args.reworked}},
		}
	end
	return widgets
end

---@param args table
---@return {previous: string?, next: string?}
function CustomPatch:getChronologyData(args)
	local informationType = self:getInformationType(args):lower()

	local data = {
		previous = CustomPatch:_getChronology('before', args.release, informationType),
		next = CustomPatch:_getChronology('after', args.release, informationType),
	}
	return data
end

---@param time 'before' | 'after'
---@param date string
---@param informationType string
---@return string
function CustomPatch:_getChronology(time, date, informationType)
	local timeModifier = time == 'before' and '<' or '>'
	return (mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::'.. informationType ..']] and [[date::'.. timeModifier .. date ..']]',
		order = 'date ' .. (time == 'before' and 'DESC' or 'ASC'),
		limit = 1,
	})[1] or {}).name
end

function CustomPatch:addToLpdb(lpdbData, args)
	lpdbData.date = args.release or args.dota

	lpdbData.extradata.version = args.name or ''
	lpdbData.extradata.new = args.new or ''
	lpdbData.extradata.nerfed = args.nerfed or ''
	lpdbData.extradata.buffed = args.buffed or ''
	lpdbData.extradata.rebalanced = args.rebalanced or ''
	lpdbData.extradata.reworked = args.reworked or ''
	lpdbData.extradata.significant = args.significant or 'no'
	lpdbData.extradata.dota2 = args.release or ''
	lpdbData.extradata.dota = args.dota or ''

	return lpdbData
end


return CustomPatch
