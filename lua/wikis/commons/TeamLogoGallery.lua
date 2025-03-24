---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamLogoGallery
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Gallery = require('Module:Gallery')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Ordinal = require('Module:Ordinal')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate') ---@module 'commons.TeamTemplate'

local TeamLogoGallery = {}

---@param args table?
---@return Html?
function TeamLogoGallery.run(args)
	args = args or {}
	local name = (args.name or mw.title.getCurrentTitle().prefixedText):gsub('_', ' '):lower()

	assert(TeamTemplate.exists(name), TeamTemplate.noTeamMessage(name))

	local imageData = TeamLogoGallery._getImageData(name, Logic.readBool(args.showPresentLogo))

	return Gallery.run(imageData)
end

---@param name string
---@param showPresentLogo boolean
---@return {imageLightMode: string, imageDarkMode: string?, caption: string}[]
function TeamLogoGallery._getImageData(name, showPresentLogo)
	local historicalTeamTemplates = Logic.emptyOr(TeamTemplate.queryHistorical(name)) or {[DateExt.defaultDate] = name}

	local imageDatas = {}
	for startDate, teamTemplate in Table.iter.spairs(historicalTeamTemplates) do
		table.insert(imageDatas, {
			startDate = startDate,
			raw = TeamTemplate.getRaw(teamTemplate)
		})
	end

	Array.forEach(imageDatas, function(imageData, index)
		imageData.endDate = (imageDatas[index + 1] or {}).startDate
	end)

	local presentImageData = showPresentLogo and imageDatas[#imageDatas] or Table.extract(imageDatas, #imageDatas)

	local finalName = presentImageData.raw.name

	local filteredImageDatas = Array.filter(imageDatas, function(imageData, index)
		local image = Logic.emptyOr(imageData.raw.image, imageData.raw.legacyimage)
		if not image or Game.isDefaultTeamLogo{logo = image} then
			return false
		end

		local previous = imageDatas[index - 1] or {raw = {}}
		local previousImage = Logic.emptyOr(previous.raw.image, previous.raw.legacyimage)
		return previousImage ~= image
	end)

	return Array.map(filteredImageDatas, function(imageData, index)
		local image = Logic.emptyOr(imageData.raw.image, imageData.raw.legacyimage)

		local caption, below = TeamLogoGallery._makeCaptionAndBelow(imageData, index, finalName)

		return {
			lightmode = image,
			darkmode = Logic.emptyOr(imageData.raw.imagedark, imageData.raw.legacyimagedark),
			caption = caption,
			below = below,
		}
	end)
end

---@param imageData {startDate: string, raw: table, endDate: string}
---@param index integer
---@param finalName string
---@return string
---@return Html|string
function TeamLogoGallery._makeCaptionAndBelow(imageData, index, finalName)
	if not imageData.endDate then
		local caption = 'Present logo'
		return caption, caption
	end

	local number = index == 1 and 'Original' or
		mw.getContentLanguage():ucfirst(Ordinal.written(index) --[[@as string]])

	local caption = number .. ' logo'
	local below = mw.html.create('p')
		:wikitext(caption)

	local teamName = imageData.raw.name
	if teamName ~= finalName then
		caption = caption .. ', as ' .. teamName
		below:wikitext(', as '):tag('b'):wikitext(teamName)
	end

	local month = DateExt.formatTimestamp('F', DateExt.readTimestamp(imageData.endDate)--[[@as integer]])
	local dateArray = mw.text.split(imageData.endDate, '-', true)
	local year = dateArray[1]
	local day = tonumber(dateArray[3])
	local daySuffix = Ordinal.suffix(day)

	caption = caption .. ' (prior to ' .. month .. ' ' .. day .. daySuffix .. ', ' .. year .. ')'

	below
		:tag('br', {selfClosing = true}):done()
		:tag('small')
			:wikitext('(prior to ' .. month .. '&nbsp;' .. day)
			:tag('sup'):wikitext(daySuffix):done()
			:wikitext(',&nbsp;' .. year .. ')')

	return caption, below
end

return Class.export(TeamLogoGallery)
