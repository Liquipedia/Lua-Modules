---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Chronology = Widgets.Chronology
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable
local Highlights = require('Module:Infobox/Widget/Highlights')

local Patch = Class.new(BasicInfobox)

function Patch.run(frame)
	local patch = Patch(frame)
	return patch:createInfobox()
end

function Patch:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = 'Patch Information'},
		Cell{name = 'Version', content = {args.version}},
		Customizable{id = 'release', children = {
				Cell{name = 'Release', content = {args.release}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				local highlights = self:getAllArgsForBase(args, 'highlight')
				if not Table.isEmpty(highlights) then
					return {
						Title{name = 'Highlights'},
						Highlights{content = highlights}
					}
				end
			end
		},
		Builder{
			builder = function()
				local chronologyData = self:getChronologyData(args)
				if not Table.isEmpty(chronologyData) then
					return {
						Title{name = 'Chronology'},
						Chronology{
							content = chronologyData
						}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() then
		infobox:categories('Patches')
		self:addToLpdb(args)
	end

	return infobox:widgetInjector(self:createWidgetInjector()):build(widgets)
end

--- Allows for overriding this functionality
function Patch:addToLpdb(args)
	local date = args.release
	local monthAndDay = mw.getContentLanguage():formatDate('m-d', date)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, {
		name = args.name,
		type = 'patch',
		information = monthAndDay,
		date = date,
	})
end

--- Allows for overriding this functionality
function Patch:getChronologyData(args)
	return { previous = args.previous, next = args.next }
end

return Patch
