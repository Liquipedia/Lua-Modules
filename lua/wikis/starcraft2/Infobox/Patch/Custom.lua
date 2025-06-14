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

---@class Starcraft2PatchInfobox: PatchInfobox
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
			Cell{name = 'SEA Release Date', content = {args.searelease}},
			Cell{name = 'NA Release Date', content = {args.narelease}},
			Cell{name = 'EU Release Date', content = {args.eurelease}},
			Cell{name = 'KR Release Date', content = {args.korrelease}},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPatch:addToLpdb(lpdbData, args)
	local date = args.narelease or args.eurelease
	local monthAndDay = mw.getContentLanguage():formatDate('m-d', date)

	lpdbData.information = monthAndDay
	lpdbData.date = date

	return lpdbData
end

---@param args table
---@return {previous: string?, previous2: string, next: string?, next2: string?}
function CustomPatch:getChronologyData(args)
	local data = {}
	if args.previous == nil and args.next == nil then
		if args.previoushbu then
			data.previous = 'Balance Update ' .. args.previoushbu .. '|#' .. args.previoushbu
		end
		if args.nexthbu then
			data.next = 'Balance Update ' .. args.nexthbu .. '|#' .. args.nexthbu
		end
	else
		if args.previous then
			data.previous = 'Patch ' .. args.previous .. '|' .. args.previous
		end
		if args.next then
			data.next = 'Patch ' .. args.next .. '|' .. args.next
		end
		if args.previoushbu then
			data.previous2 = 'Balance Update ' .. args.previoushbu .. '|#' .. args.previoushbu
		end
		if args.nexthbu then
			data.next2 = 'Balance Update ' .. args.nexthbu .. '|#' .. args.nexthbu
		end
	end

	return data
end

return CustomPatch
