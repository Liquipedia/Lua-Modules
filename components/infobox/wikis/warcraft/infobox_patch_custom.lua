---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Patch = Lua.import('Module:Infobox/Patch', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomPatch = Class.new()

local BALANCE_UPDATE = 'Balance Update'
local IGNORE_NET_EASE_RELEASE_BEFORE = DateExt.readTimestamp('2011-03-23')
local SKIP = 'skip'
local SKIPPED = 'skipped'

local _args

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	_args = customPatch.args

	customPatch.createWidgetInjector = CustomPatch.createWidgetInjector
	customPatch.getChronologyData = CustomPatch.getChronologyData
	customPatch.addToLpdb = CustomPatch.addToLpdb
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
			Cell{name = '[[Public Test Realm|PTR]] Release Date', content = {_args.release_ptr}},
			Cell{name = 'Release Date', content = {_args.release}},
			Cell{name = '[[NetEase]] Release Date', content = {CustomPatch._netEaseRelease(_args)}},
		}
	end

	return widgets
end

---@param args table
---@return string?
function CustomPatch._netEaseRelease(args)
	if not args.release or DateExt.readTimestamp(args.release) <= IGNORE_NET_EASE_RELEASE_BEFORE then
		return
	end

	return args.release_netease == SKIP and SKIPPED or args.release_netease
end

---@param args table
function CustomPatch:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.pagename, {
		name = self.name,
		type = 'patch',
		date = args.release,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json({
			beta = tostring(Logic.readBool(args.beta)),
			version = self.name,
			release = args.release,
			neteaserelease = args.release_netease ~= SKIP and args.release_netease or nil,
			ptrdate = args.release_ptr,
			balanceupdates = tostring(CustomPatch._hasBalanceUpdate(args)),
			previous = args.previous and ('Patch args.previous') or nil,
			next = args.next and ('Patch args.previous') or nil,
		})
	})
end

---@param args table
---@return {previous: string?, next: string?, previous2: string?, next2: string?}
function CustomPatch:getChronologyData(args)
	local previousBalanceUpdate, nextBalanceUpdate = CustomPatch._automaticChronologyData(args)

	local toBalanceUpdateLink = function(input)
		return input and (input .. '#Balance_Updates|' .. input) or nil
	end

	local toPatch = function(input)
		return input and ('Patch ' .. input .. '|' .. input) or nil
	end

	if not args.previous and not args.next then
		return {
			previous = toBalanceUpdateLink(previousBalanceUpdate),
			next = toBalanceUpdateLink(nextBalanceUpdate),
		}
	end

	return {
		previous = toPatch(args.previous),
		next = toPatch(args.next),
		previous2 = toBalanceUpdateLink(previousBalanceUpdate),
		next2 = toBalanceUpdateLink(nextBalanceUpdate),
	}
end

---@param args table
---@return string?
---@return string?
function CustomPatch._automaticChronologyData(args)
	if not args.release or not CustomPatch._hasBalanceUpdate(args) then
		return
	end

	local baseConditions = '[[type:patch]] AND [[extradata_balanceupdates::true]] AND '

	local previousBalanceUpdate = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = baseConditions .. '[[date::<' .. args.release .. ']]',
		order = 'date desc',
		query = 'name',
		limit = 1,
	})[1] or {}

	local nextBalanceUpdate = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = baseConditions .. '[[date::>' .. args.release .. ']]',
		order = 'date desc',
		query = 'name',
		limit = 1,
	})[1] or {}

	return previousBalanceUpdate.name, nextBalanceUpdate.name
end

---@param args table
---@return boolean
function CustomPatch._hasBalanceUpdate(args)
	return Array.any(Array.mapIndexes(function(index) return args['highlight' .. index] end), function(highlight)
		return String.contains(highlight, BALANCE_UPDATE)
	end)
end

return CustomPatch
