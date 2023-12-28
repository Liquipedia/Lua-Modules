---
-- @Liquipedia
-- wiki=halo
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

local _GAME = mw.loadData('Module:GameVersion')

local CustomPatch = Class.new(Patch)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local patch = CustomPatch(frame)
	patch.setWidgetInjector(CustomInjector(patch))

	return patch:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'customcontent' then
		return{
			Cell{name = 'Game Version', content = {CustomPatch._getGameVersion()}, options = {makeLink = true}},
		}
	end
	return widgets
end

---@param args table
function CustomPatch:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
		name = self.name,
		type = 'patch',
		information = CustomPatch:_getGameVersion(),
		date = args.release,
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
		data.previous = args.previous .. ' Patch|' .. args.previous_link
	end
	if args.next then
		data.next = args.next .. ' Patch|' .. args.next_link
	end
	return data
end

---@return string?
function CustomPatch._getGameVersion(args)
	local game = string.lower(args.game or '')
	return _GAME[game]
end

return CustomPatch
