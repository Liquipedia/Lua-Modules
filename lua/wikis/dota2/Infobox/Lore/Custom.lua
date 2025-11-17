---
-- @Liquipedia
-- page=Module:Infobox/Lore/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Lore = Lua.import('Module:Infobox/Lore')

local Widgets = Lua.import('Module:Widget/All')
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
			Title{children = 'About'},
			Cell{name = 'Names', children = {args.names}},
			Cell{name = 'Examples', children = {args.examples}},
			Cell{name = 'Members', children = {args.members}},
			Cell{name = 'Wielders', children = {args.wielders}},
			Cell{name = 'Adjectives', children = {args.adjectives}},
			Cell{name = 'Origin/Abode', children = {args.origins}},
			Cell{name = 'Family/Connections', children = {args.family}},
			Cell{name = 'Age', children = {args.age}},
			Cell{name = 'Race/Species', children = {args['race/species']}},
			Cell{name = 'Faction/s', children = {args['faction/s']}},
			Title{children = 'Associated With'},
			Cell{name = 'Heroes', children = {args.heroes}},
			Cell{name = 'Races', children = {args.race}},
			Cell{name = 'Factions', children = {args.factions}},
			Cell{name = 'Places', children = {args.places}},
			Cell{name = 'Gods', children = {args.gods}},
			Cell{name = 'Characters', children = {args.characters}},
			Cell{name = 'Species', children = {args.species}},
			Cell{name = 'Items', children = {args.items}},
			Cell{name = 'Artifacts', children = {args.artifacts}},
			Cell{name = 'Cosmetics', children = {args.cosmetics}},
			Cell{name = 'Texts', children = {args.texts}},
			Cell{name = 'Traditions', children = {args.traditions}},
			Cell{name = 'Events', children = {args.events}},
			Cell{name = 'Resources', children = {args.resources}},
			Cell{name = 'Others', children = {args.otherlinks}},
			Cell{name = '[[File:Artifact_allmode.png|16px]] Artifact', children = {
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
