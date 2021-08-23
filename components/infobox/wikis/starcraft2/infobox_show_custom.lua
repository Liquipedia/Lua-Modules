---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Show = require('Module:Infobox/Show')
local Namespace = require('Module:Namespace')
local StarCraft2Show = {}

function StarCraft2Show.run(frame)
	local show = Show(frame)
	show.addCustomCells = StarCraft2Show.addCustomCells
	return show:createInfobox(frame)
end

function StarCraft2Show:addCustomCells(infobox, args)
	infobox:cell('No. of episodes', args['num_episodes'])
	infobox:cell('Original Release', StarCraft2Show:_getReleasePeriod(args.sdate, args.edate))

	if Namespace.isMain() and args.edate == nil then
		infobox:categories('Active Shows')
	end

	return infobox
end

function StarCraft2Show:_getReleasePeriod(sdate, edate)
	if not sdate then return nil end
	return sdate .. ' - ' .. (edate or '<b>Present</b>')
end

return StarCraft2Show
