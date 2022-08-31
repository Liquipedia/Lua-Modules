---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Variables = require('Module:Variables')
local Logic = require('Module:Logic')
local Patch = require('Module:Infobox/Patch')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomPatch = Class.new()

local _args

local CustomInjector = Class.new(Injector)

function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	_args = customPatch.args
	customPatch.createWidgetInjector = CustomPatch.createWidgetInjector
	customPatch.getChronologyData = CustomPatch.getChronologyData
	customPatch.addToLpdb = CustomPatch.addToLpdb
	return customPatch:createInfobox(frame)
end

function CustomPatch:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'release' then
		return {
			Cell{
				name = 'SEA Release Date',
				content = {_args.searelease}
			},
			Cell{
				name = 'NA Release Date',
				content = {_args.narelease}
			},
			Cell{
				name = 'EU Release Date',
				content = {_args.eurelease}
			},
			Cell{
				name = 'KR Release Date',
				content = {_args.korrelease}
			},
		}
	end
	return widgets
end

function CustomPatch:addToLpdb()
	if not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		local date = _args.narelease or _args.eurelease
		local monthAndDay = mw.getContentLanguage():formatDate('m-d', date)
		mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
			name = _args.name,
			type = 'patch',
			information = monthAndDay,
			date = date,
		})
	end
end

function CustomPatch:getChronologyData()
	local data = {}
	if _args.previous == nil and _args.next == nil then
		if _args.previoushbu then
			data.previous = 'Balance Update ' .. _args.previoushbu .. '|#' .. _args.previoushbu
		end
		if _args.nexthbu then
			data.next = 'Balance Update ' .. _args.nexthbu .. '|#' .. _args.nexthbu
		end
	else
		if _args.previous then
			data.previous = 'Patch ' .. _args.previous .. '|' .. _args.previous
		end
		if _args.next then
			data.next = 'Patch ' .. _args.next .. '|' .. _args.next
		end
		if _args.previoushbu then
			data.previous2 = 'Balance Update ' .. _args.previoushbu .. '|#' .. _args.previoushbu
		end
		if _args.nexthbu then
			data.next2 = 'Balance Update ' .. _args.nexthbu .. '|#' .. _args.nexthbu
		end
	end

	return data
end

return CustomPatch
