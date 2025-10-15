---
-- @Liquipedia
-- page=Module:MainPageLayout/data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local CONTENT = {
	usefulArticles = {
		heading = 'About This Wiki',
		body = '{{Liquipedia:Useful Articles}}',
		padding = true,
		boxid = 1503,
	},
	latestUploads = {
		heading = 'Latest Uploads',
		body = '{{Special:NewFiles|limit=18}}',
		padding = true,
		boxid = 1556,
	},
}
return {
	banner = {
		lightmode = 'Commons-light-theme.svg',
		darkmode = 'Commons-dark-theme.svg',
	},
	metadesc = 'The Commons wiki is the file repository for Liquipedia',
	title = 'Commons',
	navigation = {
		{
			iconName = 'upload',
			title = 'Upload',
			link = 'Special:Upload',
			count = {},
		},
		{
			iconName = 'file_standards_guide',
			title = 'File Standards Guide',
			link = 'File_Standards_Guide',
			count = {},
		},
		{
			iconName = 'clipboard',
			title = 'Copyright Repository',
			link = 'Copyrights_Repository',
			count = {},
		},
		{
			iconName = 'copyright',
			title = 'Copyright Guide',
			link = 'hub:A_Liquipedia_Guide_to_Copyright',
			count = {},
		},
		{
			iconName = 'find_images',
			title = 'Find Files',
			link = 'Special:RunQuery/Find_images',
			count = {},
		},
	},
	layouts = {
		main = {
			{
				children = {
					{
						mobileOrder = 1,
						content = CONTENT.usefulArticles,
					},
					{
						mobileOrder = 2,
						content = CONTENT.latestUploads,
					},
				},
			},
		},
	},
}
