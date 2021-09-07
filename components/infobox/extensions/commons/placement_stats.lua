---
-- @Liquipedia
-- wiki=commons
-- page=Module:InfoboxPlacementStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local placementStats = {}
local Class = require('Module:Class')
local Template = require('Module:Template')
local Table = require('Module:Table')
local Medal = require('Module:Medal')
local Settings = require('Module:InfoboxPlacementStats/Settings')

local _PLACEMENTS = { '1', '2', '3', '>' }

function placementStats.get(args)
	args = args or {}
	local mode = args.mode or ''
	local participant = args.participant or mw.title.getCurrentTitle().prefixedText

	local queryData = placementStats._getQueryData(mode, participant)

	return placementStats:_makeTable(queryData)
end

function placementStats._getQueryData(mode, participant)
	local sortedData = { total = { top3 = 0, total = 0 } }
	for _, place in pairs(_PLACEMENTS) do
		sortedData.total[place] = 0
	end

	local query = 'count::placement'
	local baseConditions = '[[mode::' .. mode .. ']] AND [[participant::' .. participant .. ']]'

	if not Table.isEmpty(Settings.exclusionTypes) then
		baseConditions = baseConditions .. ' AND [[liquipediatiertype::!'
			.. table.concat(Settings.exclusionTypes, ']] AND [[liquipediatiertype::!')
			.. ']]'
	end

	for _, tier in pairs(Settings.tiers) do
		sortedData[tier] = { top3 = 0 }
		for _, place in pairs(_PLACEMENTS) do
			local queryData = mw.ext.LiquipediaDB.lpdb('placement', {
				conditions = baseConditions ..
					' AND [[liquipediatier::' .. tier .. ']] AND [[placement::' .. place .. ']]',
				query = query,
			})
			local count = tonumber(queryData[1].count_placement or 0) or 0
			if place ~= '>' then
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

function placementStats:_makeTable(data)
	_PLACEMENTS[#_PLACEMENTS] = nil
	local frame = mw.getCurrentFrame()
	if data.total.total > 0 then
		local output = mw.html.create('table')
			:addClass('wikitable sortable wikitable-striped wikitable-bordered')

		local tr = output:tag('tr')
		tr:tag('th')
			:wikitext('Tier')
			:css('text-align', 'left')
		for _, place in ipairs(_PLACEMENTS) do
			tr:tag('th')
				:wikitext(Medal[place])
		end
		tr:tag('th')
			:wikitext('<abbr title="Total of top 3">Top3</abbr>')
		tr:tag('th')
			:wikitext('<abbr title="Total">All</abbr>')

		_PLACEMENTS[#_PLACEMENTS + 1] = 'top3'
		_PLACEMENTS[#_PLACEMENTS + 1] = 'total'

		for _, tier in ipairs(Settings.tiers) do
			if data[tier].total > 0 then
				tr = output:tag('tr')
				local TierText = Template.safeExpand(frame, 'TierDisplay/'..tier)
				tr:tag('td')
					:wikitext('[['..TierText..'_Tournaments|'..TierText..']]')
					:css('width', '220px')
				for _, place in ipairs(_PLACEMENTS) do
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
		for _, place in ipairs(_PLACEMENTS) do
			tr:tag('th')
				:wikitext(data.total[place])
		end

	local contentDiv = mw.html.create('div')
	contentDiv:attr('class', 'fo-nttax-infobox wiki-bordercolor-light')

	local div = mw.html.create('div')

	local infoboxHeader = mw.html.create('div')
	infoboxHeader:attr('class', 'infobox-header wiki-backgroundcolor-light')
	infoboxHeader:wikitext('Placement Summary')

	div:node(infoboxHeader)
	contentDiv:node(div)

	contentDiv = contentDiv:node(output)

	return contentDiv
	else
		return ''
	end
end

return Class.export(placementStats, {frameOnly = true})
