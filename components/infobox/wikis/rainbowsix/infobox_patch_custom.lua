---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local _args

local CustomPatch = Class.new()
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
			Cell{
				name = 'Release Date',
				content = {_args.release}
			},
			Cell{
				name = 'PC Release Date',
				content = {_args.pcrelease}
			},
			Cell{
				name = 'Console Release Date',
				content = {_args.consolerelease}
			},
		}
	end
	return widgets
end

---@param args table
function CustomPatch:setLpdbData(args)
	local date = args.release or args.pcrelease or args.consolerelease
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
		name = args.name,
		type = 'patch',
		information = args.game,
		date = date,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			version = args.version,
		}
	})
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
