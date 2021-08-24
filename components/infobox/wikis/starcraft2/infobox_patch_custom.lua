---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Patch = require('Module:Infobox/Patch')

local StarCraft2Patch = {}

function StarCraft2Patch.run(frame)
	local patch = Patch(frame)
	patch.addCustomCells = StarCraft2Patch.addCustomCells
	patch.getChronologyData = StarCraft2Patch.getChronologyData
	patch.storeToLPDB = StarCraft2Patch.storeToLPDB
	return patch:createInfobox()
end

function StarCraft2Patch:addCustomCells(infobox, args)
	infobox:cell('SEA Release Date', args.searelease)
	infobox:cell('NA Release Date', args.narelease)
	infobox:cell('EU Release Date', args.eurelease)
	infobox:cell('KR Release Date', args.korrelease)
	return infobox
end

function StarCraft2Patch:storeToLPDB(infobox, args)
	local date = args.narelease or args.eurelease
	local monthAndDay = mw.getContentLanguage():formatDate('m-d', date)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
		name = args.name,
		type = 'patch',
		information = monthAndDay,
		date = date,
	})
end

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

return StarCraft2Patch
