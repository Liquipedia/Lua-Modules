local Array = require('Module:Array')
local Box = require('Module:Box')
local Class = require('Module:Class')
local Game = require('Module:Game')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Table = require('Module:Table')

local Faction = Lua.import('Module:Faction')

local FactionLists = {}

function FactionLists.getLists(args)
	return Box.start{}
	.. table.concat(
		Array.extractValues(
			Table.map(
				Faction.factions,
				function(game, factions)
					return game, FactionLists._getTable(factions, game)
				end
			),
			Table.iter.spairs
		), Box.brk{})
	.. Box.finish()
end

function FactionLists._getTable(factions, game)
	local header = Game.name{game = game} or 'Factions'
	local tbl = mw.html.create('table')
		:addClass('wikitable')
			:tag('tr')
				:tag('th')
					:attr('colspan', 3)
					:wikitext(header)
					:done()
				:done()
			:tag('tr')
				:tag('th')
					:wikitext('Civilization')
					:done()
				:tag('th')
					:wikitext('Aliases')
					:done()
				:tag('th')
					:wikitext('Identifier')
					:done()
				:done()

	local aliases = Table.groupBy(game and Faction.aliases[game] or Faction.aliases, function(_, faction) return faction end)
	for _, faction in Table.iter.spairs(factions, function(tbl, a, b) return tbl[a] < tbl[b] end) do
			tbl:tag('tr')
				:tag('th')
					:css('text-align', 'left')
					:addClass('draft')
					:addClass('faction')
					:wikitext((Faction.Icon{faction=faction, game=game, showLink=true, showTitle=true, size=64} or '') .. ' ' .. (Faction.toName(faction, {game=game}) or ''))
					:done()
				:tag('td')
					:wikitext(aliases[faction] and table.concat(Array.extractKeys(aliases[faction]), ', ') or '')
					:done()
				:tag('td')
					:wikitext(faction)
					:done()
				:done()
	end
	return tostring(tbl:allDone())
end

return Class.export(FactionLists)
