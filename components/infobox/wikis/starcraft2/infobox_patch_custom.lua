---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPatch = Class.new()

local _args

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	_args = customPatch.args
	customPatch.createWidgetInjector = CustomPatch.createWidgetInjector
	customPatch.getChronologyData = CustomPatch.getChronologyData
	customPatch.setLpdbData = CustomPatch.setLpdbData
	return customPatch:createInfobox()
end

---@return WidgetInjector
function CustomPatch:createWidgetInjector()
	return CustomInjector()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'release' then
		return {
			Cell{name = 'SEA Release Date', content = {_args.searelease}},
			Cell{name = 'NA Release Date', content = {_args.narelease}},
			Cell{name = 'EU Release Date', content = {_args.eurelease}},
			Cell{name = 'KR Release Date', content = {_args.korrelease}},
		}
	end
	return widgets
end

---@param args table
function CustomPatch:setLpdbData(args)
	if not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		local date = args.narelease or args.eurelease
		local monthAndDay = mw.getContentLanguage():formatDate('m-d', date)
		mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
			name = args.name,
			type = 'patch',
			information = monthAndDay,
			date = date,
		})
	end
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
