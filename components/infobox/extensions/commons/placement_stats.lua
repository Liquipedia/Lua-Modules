---
-- @Liquipedia
-- wiki=commons
-- page=Module:InfoboxPlacementStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local PlacementStats = {}
local Class = require('Module:Class')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Medal = require('Module:Medal')
local Config = require('Module:InfoboxPlacementStats/config')

--placements for which we query the data
--the ">" indicates all placements and is needed for the totals
local _PLACEMENTS = { '1', '2', '3', '>' }

function PlacementStats.run(args)
	args = args or {}
	local mode = args.mode or ''
	local participant = args.participant or mw.title.getCurrentTitle().prefixedText

	local queryData = PlacementStats._getQueryData(mode, participant)

	return PlacementStats:_makeTable(queryData)
end

function PlacementStats._getQueryData(mode, participant)
	local sortedData = { total = { top3 = 0, total = 0 } }
	for _, place in pairs(_PLACEMENTS) do
		sortedData.total[place] = 0
	end

	local baseConditions = '[[mode::' .. mode .. ']] AND [[participant::' .. participant .. ']]'

	if not Table.isEmpty(Config.exclusionTypes) then
		baseConditions = baseConditions .. ' AND [[liquipediatiertype::!'
			.. table.concat(Config.exclusionTypes, ']] AND [[liquipediatiertype::!')
			.. ']]'
	end

	for _, tier in pairs(Config.tiers) do
		sortedData[tier] = { top3 = 0 }
		for _, place in pairs(_PLACEMENTS) do
			local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
				conditions = baseConditions ..
					' AND [[liquipediatier::' .. tier .. ']] AND [[placement::' .. place .. ']]',
				query = 'count::placement',
			})
			local count = tonumber(queryData[1].count_placement or 0) or 0
			if place ~= _PLACEMENTS[4] then
				sortedData[tier]['top3'] = sortedData[tier]['top3'] + count
				sortedData[tier][place] = count
				sortedData.total['top3'] = sortedData.total['top3'] + count
				sortedData.total[place] = sortedData.total[place] + count
			else
				sortedData[tier].total = count
				sortedData.total.total = sortedData.total.total + count
			end
		end
	end

	return sortedData
end

function PlacementStats:_makeTable(data)
	local placements = Table.copy(_PLACEMENTS)
	placements [#placements] = nil
	local frame = mw.getCurrentFrame()
	if data.total.total > 0 then
		local output = mw.html.create('table')
			:addClass('wikitable sortable wikitable-striped wikitable-bordered')

		local tr = output:tag('tr')
		tr:tag('th')
			:wikitext('Tier')
			:css('text-align', 'left')
		for _, place in ipairs(placements) do
			tr:tag('th')
				:wikitext(Medal[place])
		end
		tr:tag('th')
			:wikitext('<abbr title="Total of top 3">Top3</abbr>')
		tr:tag('th')
			:wikitext('<abbr title="Total">All</abbr>')

		placements[#placements + 1] = 'top3'
		placements[#placements + 1] = 'total'

		for _, tier in ipairs(Config.tiers) do
			if data[tier].total > 0 then
				tr = output:tag('tr')
				local TierText = Template.safeExpand(frame, 'TierDisplay/'..tier)
				tr:tag('td')
					:wikitext('[['..TierText..'_Tournaments|'..TierText..']]')
					:css('width', '220px')
				for _, place in ipairs(placements) do
					tr:tag('td')
						:wikitext(data[tier][place])
						:css('text-align', 'center')
				end
			end
		end
		tr = output:tag('tr')
		tr:tag('th')
			:wikitext('Total')
			:css('text-align', 'left')
		for _, place in ipairs(placements) do
			tr:tag('th')
				:wikitext(data.total[place])
		end

		local contentDiv = mw.html.create('div')
		contentDiv:attr('class', 'fo-nttax-infobox wiki-bordercolor-light')

		local div = mw.html.create('div')

		local infoboxHeader = mw.html.create('div')
		infoboxHeader:attr('class', 'infobox-header')
		infoboxHeader:wikitext('Placement Summary')

		div:node(infoboxHeader)
		contentDiv:node(div)

		contentDiv = contentDiv:node(output)

		return contentDiv
	else
		return ''
	end
end

return Class.export(PlacementStats, {frameOnly = true})
