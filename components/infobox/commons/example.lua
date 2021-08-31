local BasicInfobox = require('Module:Infobox/Basic')
local Cell = require('Module:Infobox/Cell')
local Class = require('Module:Class')

local Example = Class.new(BasicInfobox)

function Example.run(frame)
	local example = Example(frame)
	return example:createInfobox()
end

function Example:createInfobox()
	local args = self.args

	return self.infobox
		:inject(self.overrideWidgets)
		:build(
			{
				Header(
					{
						name = args.name,
						image = args.image or args.default,
						caption = args.caption,
						contentTitle = 'League Information'
					}
				),
				Cell('Series', args.series),
				Cell('Organizer', args.organizer),
				Customizable(
					'tier',
					{
						Cell('Liquipedia tier', args.liquipediatier),
						Cell('Liquipedia tier type', args.liquipediatiertype)
					}
				),
				Customizable('custom', {})
			}
		)
end

function Example:overrideWidgets()
end

return Example
