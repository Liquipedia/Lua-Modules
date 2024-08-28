---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Lore/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Lore = Lua.import('Module:Infobox/Lore')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class Dota2LoreInfobox: LoreInfobox
local CustomCosmetic = Class.new(Lore)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCosmetic.run(frame)
	local lore = CustomCosmetic(frame)
	lore:setWidgetInjector(CustomInjector(lore))
	lore.args.caption = lore.args.others

	return mw.html.create():node(lore:createInfobox())
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Title{name = 'About'},
			Cell{name = 'Names', content = {args.names}},
			Cell{name = 'Examples', content = {args.examples}},
			Cell{name = 'Members', content = {args.members}},
			Cell{name = 'Wielders', content = {args.wielders}},
			Cell{name = 'Adjectives', content = {args.adjectives}},
			Cell{name = 'Origin/Abode', content = {args.origins}},
			Cell{name = 'Family/Connections', content = {args.family}},
			Cell{name = 'Age', content = {args.age}},
			Cell{name = 'Race/Species', content = {args['race/species']}},
			Cell{name = 'Faction/s', content = {args['faction/s']}},
			Title{name = 'Associated With'},
			Cell{name = 'Heroes', content = {args.heroes}},
			Cell{name = 'Races', content = {args.race}},
			Cell{name = 'Factions', content = {args.factions}},
			Cell{name = 'Places', content = {args.places}},
			Cell{name = 'Gods', content = {args.gods}},
			Cell{name = 'Characters', content = {args.characters}},
			Cell{name = 'Species', content = {args.species}},
			Cell{name = 'Items', content = {args.items}},
			Cell{name = 'Artifacts', content = {args.artifacts}},
			Cell{name = 'Cosmetics', content = {args.cosmetics}},
			Cell{name = 'Texts', content = {args.texts}},
			Cell{name = 'Traditions', content = {args.traditions}},
			Cell{name = 'Events', content = {args.events}},
			Cell{name = 'Resources', content = {args.resources}},
			Cell{name = 'Others', content = {args.otherlinks}},
			Cell{name = '[[File:Artifact_allmode.png|16px]] Artifact', content = {
				args.artifactwiki and '[[artifact:'.. args.artifactwiki ..'|'.. args.artifactwiki .. ' card]]' or nil
			}}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomCosmetic:getWikiCategories(args)
	local categoryLookup = {
		artifact = 'Lore artifacts',
		character = 'Characters',
		event = 'Lore events',
		faction = 'Factions',
		god = 'Gods',
		hero = 'Hero lore',
		race = 'Races',
		resource = 'Lore resources',
		species = 'Species',
		text = 'Texts',
		tradition = 'Lore traditions',
		world = 'World',
	}

	local function getCategoryFromType(type)
		return categoryLookup[type] or 'Miscellaneous lore'
	end

	return {getCategoryFromType(string.lower(args.type or ''))}
end

function CustomCosmetic:setLpdbData(args)
	mw.ext.LiquipediaDB.lpdb_datapoint('lore_' .. self.pagename, {
		name = args.name or self.pagename,
		type = 'lore',
		image = args.image,
		imagedark = args.imagedark,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json{
			type = args.type,
		},
	})
end

return CustomCosmetic
