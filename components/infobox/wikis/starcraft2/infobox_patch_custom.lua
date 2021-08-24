---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Patch = require('Module:Infobox/Patch')
local Namespace = require('Module:Namespace')

local StarCraft2Patch = {}

function StarCraft2Patch.run(frame)
	local patch = Patch(frame)
	patch.addCustomCells = StarCraft2Patch.addCustomCells
	patch.getChronologyData = StarCraft2Patch.getChronologyData
	return patch:createInfobox()
end

--- Allows for overriding this functionality
function StarCraft2Patch:addCustomCells(infobox, args)
	infobox:cell('SEA Release Date', args.searelease)
	infobox:cell('NA Release Date', args.narelease)
	infobox:cell('EU Release Date', args.eurelease)
	infobox:cell('KR Release Date', args.korrelease)
	if Namespace.isMain then
		StarCraft2Patch:_storeToDatapoint(args)
	end
	return infobox
end

function StarCraft2Patch:_storeToDatapoint(args)
	local date = args.narelease or args.eurelease
	local monthAndDay = mw.getContentLanguage():formatDate('m-d', date)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. (args.name or mw.title.getCurrentTitle().text), {
		name = args.name,
		type = 'patch',
		information = monthAndDay,
		date = date,
	})
end

--- Allows for overriding this functionality
function StarCraft2Patch:getChronologyData(args)
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
			data.next = 'Patch ' .. args.previous .. '|' .. args.next
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

return StarCraft2Patch
