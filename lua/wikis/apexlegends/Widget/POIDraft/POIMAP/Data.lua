---
-- @Liquipedia
-- page=Module:Widget/POIDraft/POIMap/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@class POIDraftDateBoundItem
---@field startDate string?
---@field endDate string?

---@class PoiData: POIDraftDateBoundItem
---@field name string
---@field x number
---@field y number
---@field mobileName string
---@field mobileX number?
---@field mobileY number?
---@field hideIfAny string[]?
---@field hideIfAllMissing string[]?
---@field startDate string?
---@field endDate string?

---@class MapImageData: POIDraftDateBoundItem
---@field file string

---@class PoiMapData
---@field name string
---@field image MapImageData[]
---@field width integer
---@field mobileWidth integer
---@field pois PoiData[]

---@type table<string, PoiMapData>
local MAPS_DATA = {
	StormPoint = {
		name = 'Storm Point',
		image = {
			{ file = 'Storm_Point_S17.png' }
		},
		width = 800,
		mobileWidth = 365,
		pois = {
			{ name = 'Barometer', x = 0.370, y = 0.666, mobileName = 'Barometer', startDate = '2025-05-01' },
			{ name = 'Barometer North', x = 0.370, y = 0.666, mobileName = 'Barometer N.', endDate = '2025-04-30' },
			{ name = 'Barometer South', x = 0.307, y = 0.796, mobileName = 'Barometer S.', endDate = '2025-04-30' },
			{ name = 'Basin Armory', x = 0.240, y = 0.581, mobileName = 'Basin Armory', startDate = '2025-08-30' },
			{ name = 'Cascade Falls', x = 0.497, y = 0.396, mobileName = 'Cascade<br>Falls' },
			{ name = 'Cenote Cave', x = 0.192, y = 0.716, mobileName = 'Cenote Cave' },
			{ name = 'Ceto Station', x = 0.347, y = 0.506, mobileName = 'Ceto Station' },
			{ name = 'Checkpoint', x = 0.307, y = 0.326, mobileName = 'Checkpoint', mobileY = 0.333 },
			{ name = 'Checkpoint North', x = 0.307, y = 0.326, mobileName = 'Checkpoint N.', mobileY = 0.333, endDate = '2025-04-30' },
			{ name = 'Checkpoint South', x = 0.267, y = 0.401, mobileName = 'Checkpoint S.', endDate = '2025-04-30' },
			{ name = 'Cliff Side', x = 0.880, y = 0.366, mobileName = 'Cliff Side', endDate = '2025-04-30' },
			{ name = 'Coastal Camp', x = 0.477, y = 0.856, mobileName = 'Coastal<br>Camp' },
			{ name = 'Command Center', x = 0.647, y = 0.316, mobileName = 'Command Center' },
			{ name = 'Devastated Coast', x = 0.827, y = 0.776, mobileName = 'Devastated Coast' },
			{ name = 'Downed Beast', x = 0.105, y = 0.296, mobileName = 'Downed Beast', mobileX = 0.120 },
			{ name = 'East Trail', x = 0.880, y = 0.366, mobileName = 'East Trail', startDate = '2025-05-01' },
			{ name = 'Echo HQ', x = 0.677, y = 0.846, mobileName = 'Echo HQ' },
			{ name = 'Forbidden Zone', x = 0.477, y = 0.581, mobileName = 'Forbidden<br>Zone', mobileY = 0.585, startDate = '2025-05-01' },
			{ name = 'Jurassic', x = 0.477, y = 0.581, mobileName = 'Jurassic', endDate = '2025-04-30' },
			{ name = 'Launch Pad', x = 0.787, y = 0.656, mobileName = 'Launch Pad' },
			{ name = 'Lift', x = 0.577, y = 0.496, mobileName = 'Lift', endDate = '2025-04-30' },
			{ name = 'Lightning Rod', x = 0.787, y = 0.236, mobileName = 'Lightning Rod' },
			{ name = 'Mountain Lift', x = 0.577, y = 0.496, mobileName = 'Mountain<br>Lift', startDate = '2025-05-01' },
			{ name = 'North Pad', x = 0.237, y = 0.156, mobileName = 'North Pad' },
			{ name = 'Outpost North', x = 0.407, y = 0.236, mobileName = 'Outpost North', startDate = '2025-05-01' },
			{ name = 'Prowler Nest', x = 0.747, y = 0.516, mobileName = 'Prowler Nest', endDate = '2025-04-30' },
			{ name = 'Storm Catcher', x = 0.727, y = 0.418, mobileName = 'Storm<br>Catcher' },
			{ name = 'The Mill', x = 0.147, y = 0.506, mobileName = 'The Mill' },
			{ name = 'The Pylon', x = 0.587, y = 0.676, mobileName = 'The Pylon', mobileY = 0.690 },
			{ name = 'The Wall', x = 0.527, y = 0.166, mobileName = 'The Wall' },
			{ name = 'Trident', x = 0.407, y = 0.236, mobileName = 'Trident', endDate = '2025-04-30' },
			{ name = 'Zeus Station', x = 0.767, y = 0.106, mobileName = 'Zeus Station' }
		}
	},
	WorldsEdge = {
		name = "World's Edge",
		image = {
			{ file = 'World_Edge_S17.png' }
		},
		width = 800,
		mobileWidth = 365,
		pois = {
			{ name = 'Big Maude', x = 0.762, y = 0.696, mobileName = 'Big Maude' },
			{ name = 'Climatizer', x = 0.702, y = 0.146, mobileName = 'Climatizer', startDate = '2025-02-03' },
			{ name = 'Climatizer East', x = 0.772, y = 0.236, mobileName = 'Climatizer East', endDate = '2025-04-30' },
			{ name = 'Climatizer West', x = 0.672, y = 0.126, mobileName = 'Climatizer West', endDate = '2025-04-30' },
			{ name = 'Countdown', x = 0.302, y = 0.336, mobileName = 'Countdown' },
			{ 
				name = 'Fragment', x = 0.642, y = 0.476, mobileName = 'Fragment',
				hideIfAny = {'Fragment East team', 'Fragment West team'}
			},
			{ 
				name = 'Fragment East', x = 0.672, y = 0.476, mobileName = 'Fragment E.',
				hideIfAllMissing = {'Fragment East team', 'Fragment West team'}
			},
			{ 
				name = 'Fragment West', x = 0.492, y = 0.456, mobileName = 'Fragment W.',
				hideIfAllMissing = {'Fragment East team', 'Fragment West team'}
			},
			{ name = 'The Geyser', x = 0.762, y = 0.596, mobileName = 'The Geyser' },
			{ name = 'Harvester', x = 0.442, y = 0.616, mobileName = 'Harvester' },
			{ name = 'Landslide', x = 0.340, y = 0.456, mobileName = 'Landslide' },
			{ name = 'Lava Fissure', x = 0.148, y = 0.400, mobileName = 'Lava Fissure' },
			{ name = 'Lava Siphon', x = 0.542, y = 0.726, mobileName = 'Lava Siphon' },
			{ name = 'Launch Site', x = 0.522, y = 0.896, mobileName = 'Launch<br>Site' },
			{ name = 'Mirage A Trois', x = 0.149, y = 0.510, mobileName = 'Mirage A Trois' },
			{ name = 'Monument', x = 0.492, y = 0.386, mobileName = 'Monument' },
			{ name = 'Overlook', x = 0.822, y = 0.396, mobileName = 'Overlook' },
			{ name = 'Skyhook East', x = 0.388, y = 0.166, mobileName = 'Skyhook East' },
			{ name = 'Skyhook West', x = 0.200, y = 0.236, mobileName = 'Skyhook West' },
			{ name = 'Stacks', x = 0.712, y = 0.826, mobileName = 'Stacks' },
			{ name = 'Staging', x = 0.222, y = 0.596, mobileName = 'Staging' },
			{ name = 'Survey Camp', x = 0.477, y = 0.231, mobileName = 'Survey Camp' },
			{ name = 'The Dome', x = 0.725, y = 0.930, mobileName = 'The Dome' },
			{ name = 'The Epicenter', x = 0.622, y = 0.296, mobileName = 'The Epicenter' },
			{ name = 'The Tree', x = 0.392, y = 0.826, mobileName = 'The Tree' },
			{ name = 'Thermal Station', x = 0.222, y = 0.756, mobileName = 'Thermal Station' }
		}
	},
	EDistrict = {
		name = 'E-District',
		image = {
			{ file = 'Apex_Legends_E-District_Map.png' }
		},
		width = 800,
		mobileWidth = 365,
		pois = {
			{ name = 'Blossom Drive', x = 0.092, y = 0.516, mobileName = 'Blossom<br>Drive' },
			{ name = 'Boardwalk', x = 0.122, y = 0.356, mobileName = 'Boardwalk' },
			{ name = 'Canal Plaza', x = 0.472, y = 0.306, mobileName = 'Canal Plaza' },
			{ name = 'City Hall', x = 0.300, y = 0.410, mobileName = 'City Hall' },
			{ name = 'Draft Point', x = 0.442, y = 0.656, mobileName = 'Draft Point' },
			{ name = 'Electro Dam', x = 0.662, y = 0.176, mobileName = 'Electro Dam' },
			{ name = 'Energy Bank', x = 0.492, y = 0.426, mobileName = 'Energy<br>Bank' },
			{ name = 'Galleria', x = 0.622, y = 0.360, mobileName = 'Galleria' },
			{ name = 'Heights', x = 0.812, y = 0.346, mobileName = 'Heights' },
			{ name = 'Humbert Labs', x = 0.682, y = 0.786, mobileName = 'Humbert Labs' },
			{ name = 'Neon Square', x = 0.277, y = 0.540, mobileName = 'Neon Square', mobileY = 0.570 },
			{ name = 'Old Town', x = 0.605, y = 0.906, mobileName = 'Old Town' },
			{ name = 'Resort', x = 0.188, y = 0.236, mobileName = 'Resort' },
			{ name = 'Settlement', x = 0.597, y = 0.596, mobileName = 'Settlement' },
			{ name = 'Shipyard Arcade', x = 0.412, y = 0.896, mobileName = 'Shipyard<br>Arcade', mobileY = 0.880 },
			{ name = 'Stadium', x = 0.792, y = 0.556, mobileName = 'Stadium' },
			{ name = 'Street Market', x = 0.192, y = 0.706, mobileName = 'Street Market' },
			{ name = 'The Lotus', x = 0.422, y = 0.146, mobileName = 'The Lotus' },
			{ name = 'Uptown', x = 0.682, y = 0.476, startDate = '2025-02-03' },
			{ name = 'Vibe Isle', x = 0.682, y = 0.476, endDate = '2025-02-03' },
			{ name = 'Viaduct', x = 0.342, y = 0.776, mobileName = 'Viaduct' }
		}
	},
	Olympus = {
		name = 'Olympus',
		image = {
			{ file = 'Apex legends Olympus S27 map.png' }
		},
		width = 800,
		mobileWidth = 365,
		pois = {
			{ name = 'Bonsai Plaza', x = 0.540, y = 0.900, mobileName = 'Bonsai<br>Plaza' },
			{ name = 'Carrier', x = 0.210, y = 0.280, mobileName = 'Carrier' },
			{ name = 'Clinic', x = 0.912, y = 0.465, mobileName = 'Clinic' },
			{ name = 'Dockyard', x = 0.130, y = 0.610, mobileName = 'Dockyard' },
			{ name = 'Elysium', x = 0.820, y = 0.860, mobileName = 'Elysium' },
			{ name = 'Estates', x = 0.310, y = 0.525, mobileName = 'Estates' },
			{ name = 'Fight Night', x = 0.400, y = 0.310, mobileName = 'Fight Night' },
			{ name = 'Gardens', x = 0.742, y = 0.440, mobileName = 'Gardens' },
			{ name = 'Gravity Engine', x = 0.575, y = 0.430, mobileName = 'Gravity<br>Engine' },
			{ name = 'Grow Towers', x = 0.730, y = 0.560, mobileName = 'Grow Towers' },
			{ name = 'Hammond Labs', x = 0.515, y = 0.530, mobileName = 'Hammond<br>Labs' },
			{ name = 'Hydroponics', x = 0.210, y = 0.710, mobileName = 'Hydroponics' },
			{ name = 'Icarus', x = 0.730, y = 0.920, mobileName = 'Icarus' },
			{ name = 'Oasis', x = 0.165, y = 0.410, mobileName = 'Oasis' },
			{ name = 'Phase Driver', x = 0.390, y = 0.830, mobileName = 'Phase Driver' },
			{ name = 'Power Grid', x = 0.500, y = 0.240, mobileName = 'Power Grid' },
			{ name = 'Rift', x = 0.690, y = 0.260, mobileName = 'Rift' },
			{ name = 'Solar Array', x = 0.620, y = 0.750, mobileName = 'Solar<br>Array' },
			{ name = 'Somers University', x = 0.810, y = 0.720, mobileName = 'Somers University' },
			{ name = 'Stabilizer', x = 0.360, y = 0.180, mobileName = 'Stabilizer' },
			{ name = 'Terminal', x = 0.480, y = 0.650, mobileName = 'Terminal' },
			{ name = 'Turbine', x = 0.380, y = 0.420, mobileName = 'Turbine' }
		}
	}
}

return MAPS_DATA
