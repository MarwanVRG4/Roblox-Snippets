--// Procedural Generation System by @MarwanVRG4

local module = {}
local organizedPlants = {} -- Organizes Plants According to Rarity then to their Biome

local Gamerules = require(script.Parent.Parent.Dictionary.Gamerules)
local Biomes = require(script.Parent.Parent.Dictionary.Biomes)

local Status = workspace.Status

local RepStorage = game:GetService("ReplicatedStorage")
local Plants = RepStorage:WaitForChild("Plants")

local TRANSITION_THRESHOLD = 0.08
local PLANT_DENSITY = 0.1
local SUB_BIOME_RANGE = { 6, 9 }
local SUB_BIOME_MAX_COUNT = 250
module.Y_INCREMENT = 5

local RNG = Random.new()

local clamp = math.clamp
local noise = math.noise
local abs = math.abs
local lerp = math.lerp
local sqrt = math.sqrt
local round = math.round
local floor = math.floor

for x = -Gamerules.WorldRadius / Gamerules.ChunkSize, Gamerules.WorldRadius / Gamerules.ChunkSize do
	for z = -Gamerules.WorldRadius / Gamerules.ChunkSize, Gamerules.WorldRadius / Gamerules.ChunkSize do
		local model = Instance.new("Model")
		model.Name = x .. "_" .. z
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model.Parent = workspace.World.Terrain
	end
end

for _, plant in pairs(Plants:GetChildren()) do
	local biome = plant:GetAttribute("Biome")
	local rarity = plant:GetAttribute("Rarity")
	if not biome then
		continue
	end -- Eg. Thunderfruit

	if not organizedPlants[biome] then
		organizedPlants[biome] = {}
	end
	if not organizedPlants[biome][rarity] then
		organizedPlants[biome][rarity] = {}
	end
	table.insert(organizedPlants[biome][rarity], plant)
end

local totalBlocks = (Gamerules.WorldRadius / Gamerules.BlockSize * 2 + 1) ^ 2
local totalChunks = (Gamerules.WorldRadius / Gamerules.ChunkSize * 2 + 1) ^ 2

module.ChunkSlopes = {} -- Holds the Average slope of each chunk sorted from lowest to highest

module.getChunk = function(X, Z)
	return workspace.World.Terrain[tostring(round(floor(X / Gamerules.ChunkSize))) .. "_" .. tostring(
		round(floor(Z / Gamerules.ChunkSize))
	)]
end

module.nearestMultiple = function(n, m)
	return round(n / m) * m
end

module.Generate = function(Scale, Frequency, Amplitude, Seed)
	local initial = tick()

	local blockProgress = 0
	Status.Value = "Clearing World..."
	Status.Generating.Value = true

	--// Clear Plants (Blocks Are Recycled)

	for _, plant in pairs(workspace.World.Spawned:GetChildren()) do
		if plant.Value then
			plant.Value:Destroy()
		end
		plant:Destroy()
	end
	Status.Value = "Generating World..."

	--------------------------------------------

	if not Seed then
		Seed = RNG:NextNumber(-9999999, 9999999)
	end
	local featureDensities = {}
	local subBlocks = {}

	for x = -Gamerules.WorldRadius / Gamerules.BlockSize, Gamerules.WorldRadius / Gamerules.BlockSize do
		for z = -Gamerules.WorldRadius / Gamerules.BlockSize, Gamerules.WorldRadius / Gamerules.BlockSize do
			blockProgress += 1
			Status.Value = "Generating World... (" .. blockProgress .. "/" .. totalBlocks .. ")"

			local realX, realZ = x * Gamerules.BlockSize, z * Gamerules.BlockSize
			local distance = sqrt(realX ^ 2 + realZ ^ 2)
			if distance > Gamerules.WorldRadius then
				continue
			end -- Keep the Circle Shape Using Radius

			local continentalness = lerp( -- Lerp between Mountain and Plains based on the Blend Y
				clamp(noise(x / Scale * Frequency * 2, z / Scale * Frequency * 2, Seed) + 0.5, 0, 1) * (Amplitude / 3), -- Plains Map
				clamp(noise(x / Scale * Frequency / 3, z / Scale * Frequency / 3, Seed) + 0.5, 0, 1) * Amplitude * 5, -- Mountains Map
				clamp(noise(x / Scale * Frequency, z / Scale * Frequency, Seed) + 0.5, 0, 1) -- Blend Map
			) -- Clamped Range to [0,1]

			local temperature = clamp(noise(x / 3 * Frequency, z / 3 * Frequency, Seed) + 0.5, 0, 1)
			local humidity = clamp(noise(x / 2 * Frequency, z / 2 * Frequency, Seed) + 0.5, 0, 1)
			local subNoise = clamp(noise(x / 3 * Frequency * 6, z / 3 * Frequency * 6, Seed - 1) + 0.5, 0, 1) -- Sub-Biomes
			local beach = (distance / Gamerules.WorldRadius) ^ 3.2 -- Cubed to become effective towards the end only (Transition to Beach)

			local y =
				module.nearestMultiple(round(continentalness * (1 - beach) * Gamerules.BlockSize), module.Y_INCREMENT)
			local chosenChunk = module.getChunk(realX, realZ)

			local biome = "Beach"

			if beach < 0.95 then
				if temperature < 0.3 then
					biome = "Snow"
				elseif temperature > 0.8 then
					biome = "Desert"
				else
					if humidity >= 0.6 then
						biome = "Forest"
					else
						biome = "Plains"
					end
				end

				table.insert(
					featureDensities,
					{ realX, realZ, clamp(noise(x / 0.5 * 0.1, z / 0.5 * 0.1, Seed) + 0.5, 0, 1) }
				) -- Feature Density for Blocks (Determining Plants)
			end

			local block = (#module.ChunkSlopes > 0 and chosenChunk[realX .. "_" .. realZ]) or script.Block:Clone()
			block.Name = realX .. "_" .. realZ
			block.CFrame = CFrame.new(realX, 0.5 + (y / 2), realZ)
			block.Size = Vector3.new(Gamerules.BlockSize, 1 + y, Gamerules.BlockSize)

			if block:GetAttribute("DefaultY") then
				block:SetAttribute("DefaultY", nil)
			end -- So when bases replot, no changes happen to the world

			local finalColor = Biomes[biome].Color

			if biome ~= "Beach" and Biomes[biome].Sub then -- Not Beach & Main Biome
				if biome == "Forest" or biome == "Plains" then
					if abs(humidity - 0.6) <= TRANSITION_THRESHOLD then
						finalColor =
							finalColor:Lerp(Biomes.Forest.Color, 1 - (abs(humidity - 0.6) / TRANSITION_THRESHOLD))
					elseif abs(humidity - 0.4) <= TRANSITION_THRESHOLD then
						finalColor =
							finalColor:Lerp(Biomes.Plains.Color, 1 - (abs(humidity - 0.4) / TRANSITION_THRESHOLD))
					end
				end
				if abs(temperature - 0.3) <= TRANSITION_THRESHOLD then
					finalColor = finalColor:Lerp(Biomes.Snow.Color, 1 - (abs(temperature - 0.3) / TRANSITION_THRESHOLD))
				elseif abs(temperature - 0.8) <= TRANSITION_THRESHOLD then
					finalColor =
						finalColor:Lerp(Biomes.Desert.Color, 1 - (abs(temperature - 0.8) / TRANSITION_THRESHOLD))
				end
			end
			if abs(beach - 0.95) <= TRANSITION_THRESHOLD then
				finalColor = finalColor:Lerp(Biomes.Beach.Color, 1 - (abs(beach - 0.95) / TRANSITION_THRESHOLD))
			end

			block.Color = finalColor
			block.Material = Enum.Material.SmoothPlastic

			if subNoise >= 0.7 and beach < 0.95 then
				if not subBlocks[realX] then
					subBlocks[realX] = {}
				end
				subBlocks[realX][realZ] = { block, biome, chosenChunk }
			else
				block:SetAttribute("Biome", biome)
				block.Parent = chosenChunk
			end
		end

		if x % (Gamerules.BlockSize * 10) == 0 then
			task.wait()
		end -- Prevent Exhaustion
	end

	--// Sub-Biomes

	local countSubBiomes = math.random(SUB_BIOME_RANGE[1], SUB_BIOME_RANGE[2])
	for i = 1, countSubBiomes do -- Set Sub-Biome Cores
		workspace.Status.Value = "Configuring Sub-Biomes (" .. i .. "/" .. countSubBiomes .. ")"

		local att = 0
		local x, z, blockData
		repeat
			x = module.nearestMultiple(
				RNG:NextInteger(-Gamerules.WorldRadius * 0.7, Gamerules.WorldRadius * 0.7),
				Gamerules.BlockSize
			)
			z = module.nearestMultiple(
				RNG:NextInteger(-Gamerules.WorldRadius * 0.7, Gamerules.WorldRadius * 0.7),
				Gamerules.BlockSize
			)
			blockData = subBlocks[x][z]
		until blockData or att >= 10
		if not blockData or att >= 10 then
			continue
		end

		local block, biome, chunk = unpack(blockData)
		biome = Biomes[biome].Sub
		block:SetAttribute("Biome", biome)
		block.Color = Biomes[biome].Color
		block.Material = Biomes[biome].Material
		block.Parent = chunk
		chunk:SetAttribute("Occupied", true)

		--// Expand Cores Using Sub-Noise Map

		local neighbourQueue = {
			{ x - Gamerules.BlockSize, z },
			{ x + Gamerules.BlockSize, z },
			{ x, z - Gamerules.BlockSize },
			{
				x,
				z + Gamerules.BlockSize,
			},
		}
		local countBlocks = 0

		while #neighbourQueue > 0 do
			for i, neighbourPos in pairs(neighbourQueue) do
				table.remove(neighbourQueue, i)
				x, z = unpack(neighbourPos)
				if not subBlocks[x][z] then
					continue
				end
				local neighbour, _, neighbourChunk = unpack(subBlocks[x][z])
				neighbour:SetAttribute("Biome", biome)
				neighbour.Color = block.Color
				neighbour.Material = block.Material
				neighbour.Parent = neighbourChunk
				countBlocks += 1
				if countBlocks >= SUB_BIOME_MAX_COUNT then
					continue
				end -- Don't Check for New neighbours if Above Max Count

				for _, newNeighbourPos in pairs({
					{ x - Gamerules.BlockSize, z },
					{ x + Gamerules.BlockSize, z },
					{ x, z - Gamerules.BlockSize },
					{ x, z + Gamerules.BlockSize },
				}) do
					x, z = unpack(newNeighbourPos)
					if not subBlocks[x][z] then
						continue
					end
					neighbour, _, neighbourChunk = unpack(subBlocks[x][z])
					if not neighbour.Parent then
						table.insert(neighbourQueue, newNeighbourPos)
					end
				end
			end
		end

		task.wait() -- Prevent Exhaustion
	end

	for x, coloumns in pairs(subBlocks) do -- Fill Sub-Noise Blocks that were not used
		for z, blockData in pairs(coloumns) do
			local block, biome, chunk = unpack(blockData)
			if not block.Parent then
				block:SetAttribute("Biome", biome)
				block.Parent = chunk
			end
		end
	end

	print("World Generation Complete in " .. tick() - initial .. "s")
	initial = tick()

	--// Set Average Slope for Chunks

	module.ChunkSlopes = {}

	for i, chunk in pairs(workspace.World.Terrain:GetChildren()) do
		local totalSlope, children = 0, chunk:GetChildren()

		Status.Value = "Configuring Chunks... (" .. i .. "/" .. totalChunks .. ")"

		for _, block in pairs(children) do
			local x, z = table.unpack(string.split(block.Name, "_"))
			x = tonumber(x)
			z = tonumber(z)
			local neighbours = {
				{ x - Gamerules.BlockSize, z },
				{ x + Gamerules.BlockSize, z },
				{ x, z - Gamerules.BlockSize },
				{ x, z + Gamerules.BlockSize },
			}
			local diffSum = 0

			for _, pos in pairs(neighbours) do
				local nBlock = chunk:FindFirstChild(pos[1] .. "_" .. pos[2])
				if nBlock then
					diffSum += abs(block.Size.Y - nBlock.Size.Y)
				end
			end
			totalSlope += diffSum / #neighbours
		end

		if #children > 0 then
			table.insert(module.ChunkSlopes, { chunk, totalSlope / #children })
		end

		if i % 10 == 0 then
			task.wait()
		end -- Prevent Exhaustion
	end

	table.sort(module.ChunkSlopes, function(a, b)
		return a[2] < b[2]
	end) -- Sort from Lowest -- > Greatest, Used for Loops when Plotting Base

	task.wait() -- Prevent Exhaustion

	print("Chunk Slopes Set in " .. tick() - initial .. "s")
	Status.Value = "Populating World..."
	initial = tick()

	--// Distribute Biome Features

	table.sort(featureDensities, function(a, b)
		return a[3] > b[3]
	end) -- Sort from Lowest to Highest Density
	-- local decorationBlocks = {} -- Blocks within top X% of their Biome are decorations

	--// Populate World with Plants

	local plantBlocks = {}
	for i = 1, floor(#featureDensities * PLANT_DENSITY) do
		table.insert(plantBlocks, featureDensities[i])
	end -- Top X% are Plants

	for i, pos in pairs(plantBlocks) do
		for j, loopedPos in pairs(plantBlocks) do -- Remove blocks that are too close to each other
			if
				(pos[1] ~= loopedPos[1] or pos[2] ~= loopedPos[2])
				and sqrt((pos[1] - loopedPos[1]) ^ 2 + (pos[2] - loopedPos[2]) ^ 2) <= 16
			then
				table.remove(plantBlocks, j)
			end
		end

		Status.Value = "Populating World... (" .. i .. "/" .. #plantBlocks .. ")"
		if i % 50 == 0 then
			task.wait()
		end -- Prevent Exhaustion
	end

	print("Plant Blocks set in " .. tick() - initial .. "s")
	initial = tick()

	for i, pos in pairs(plantBlocks) do
		local block = module.getChunk(pos[1], pos[2])[pos[1] .. "_" .. pos[2]]
		local biome = block:GetAttribute("Biome")
		if not organizedPlants[biome] and Biomes[biome].Main then
			biome = Biomes[biome].Main
		end
		local roll = RNG:NextNumber(0, 100)

		local chosenRarity
		local total = 0
		for rarity, data in pairs(Gamerules.Rarities) do
			if rarity == "Exclusive" then
				continue
			end
			total += data.Chance
			if roll <= total then
				chosenRarity = (rarity == "Mythic" and not organizedPlants[biome][rarity] and "Legendary") or rarity
				break
			end
		end

		local globalPlants = organizedPlants.Global[chosenRarity]
		local eligiblePlants = organizedPlants[biome][chosenRarity]

		local chosenPlant = (globalPlants and math.random(1, 3) == 1 and globalPlants[math.random(1, #globalPlants)])
			or eligiblePlants[math.random(1, #eligiblePlants)]
		if chosenPlant then
			chosenPlant = chosenPlant:GetChildren()[math.random(1, #chosenPlant:GetChildren())]:Clone()
			chosenPlant:PivotTo(
				CFrame.new(pos[1], block.Size.Y, pos[2]) * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
			)
			chosenPlant.Parent = block.Parent

			local objValue = Instance.new("ObjectValue")
			objValue.Value = chosenPlant
			objValue.Name = chosenPlant.Name
			objValue.Parent = workspace.World.Spawned
		end
	end

	Status.Value = "Waiting For Server..."
	Status.Generating.Value = false
	print("World Generated: " .. tick() - initial .. "s")
end

module.ChunkOccupied = function(name)
	if workspace.World.Terrain[name]:GetAttribute("Occupied") then
		return true
	end -- Eg. Travelling Merchant or Sub-Biomes
	for _, base in pairs(workspace.World.Bases:GetChildren()) do
		if base:GetAttribute("Chunk") == name then
			return true
		end
	end
	return false
end

module.HidePlants = function(chunk, minX, minZ, maxX, maxZ) -- Hide Plants that overlap with the base
	local hiddenPlants = {}
	for _, obj in pairs(chunk:GetChildren()) do
		local pos = obj:GetPivot()
		if
			RepStorage.Plants:FindFirstChild(obj.Name)
			and pos.X >= minX
			and pos.X <= maxX
			and pos.Z >= minZ
			and pos.Z <= maxZ
		then
			obj.Parent = RepStorage.Runtime
			table.insert(hiddenPlants, obj)
		end
	end
	return hiddenPlants
end

module.FlattenArea = function(chunk, minX, minZ, maxX, maxZ)
	local averageHeight = 0
	local totalBlocks = {}

	for x = minX, maxX, Gamerules.BlockSize do
		for z = minZ, maxZ, Gamerules.BlockSize do
			local block = chunk:FindFirstChild(x .. "_" .. z)
			if block then
				averageHeight += block.Size.Y
				table.insert(totalBlocks, block)
			end
		end
	end
	averageHeight = module.nearestMultiple(averageHeight / #totalBlocks, module.Y_INCREMENT)

	for _, block in pairs(totalBlocks) do -- Flatten Blocks under Base using Average Height
		block:SetAttribute("DefaultY", block.Size.Y - 1)
		block.CFrame = CFrame.new(block.Position.X, 0.5 + (averageHeight / 2), block.Position.Z)
		block.Size = Vector3.new(Gamerules.BlockSize, 1 + averageHeight, Gamerules.BlockSize)
	end

	module.HidePlants(chunk, minX, minZ, maxX, maxZ)

	return averageHeight
end

module.UndoFlatten = function(chunk)
	for _, block in pairs(chunk:GetChildren()) do
		local defY = block:GetAttribute("DefaultY")
		if defY then
			block.CFrame = CFrame.new(block.Position.X, 0.5 + (defY / 2), block.Position.Z)
			block.Size = Vector3.new(Gamerules.BlockSize, 1 + defY, Gamerules.BlockSize)
			block:SetAttribute("DefaultY", nil)
		end
	end

	for _, obj in pairs(RepStorage.Runtime:GetChildren()) do
		local pos = obj:IsA("PVInstance") and obj:GetPivot().Position
		if RepStorage.Plants:FindFirstChild(obj.Name) and pos and module.getChunk(pos.X, pos.Z) == chunk then
			obj.Parent = chunk
		end
	end
end

module.PlotBase = function(player, target)
	local chosenChunk
	local playerBase = workspace.World.Bases:FindFirstChild(player.UserId)

	if not target then
		local attempt = 0
		repeat
			attempt += 1
			local chunk = module.ChunkSlopes[math.random(1, math.floor(#module.ChunkSlopes / 4))][1]
			if
				chunk:GetPivot().Position.Magnitude >= Gamerules.WorldRadius * 0.85 or module.ChunkOccupied(chunk.Name)
			then
				continue
			end
			chosenChunk = chunk
		until chosenChunk or attempt >= 50
	else
		if target.Magnitude >= Gamerules.WorldRadius * 0.85 then
			return "Far"
		end -- If too far from center

		chosenChunk = module.getChunk(target.X, target.Z)
		if module.ChunkOccupied(chosenChunk.Name) then
			return "Occupied"
		end
	end

	if not chosenChunk or not script.Parent.Parent.GameReady.Value then
		return
	end

	if not playerBase then
		playerBase = RepStorage.BaseTemplate:Clone()
		playerBase.Name = player.UserId
	else
		module.UndoFlatten(workspace.World.Terrain[playerBase:GetAttribute("Chunk")])
	end

	local chunkCenterX, chunkCenterZ = table.unpack(string.split(chosenChunk.Name, "_"))
	chunkCenterX = tonumber(chunkCenterX) * Gamerules.ChunkSize + (Gamerules.ChunkSize / 2)
	chunkCenterZ = tonumber(chunkCenterZ) * Gamerules.ChunkSize + (Gamerules.ChunkSize / 2)

	local minX, maxX =
		module.nearestMultiple(-playerBase.PrimaryPart.Size.X / 2 + chunkCenterX, Gamerules.BlockSize),
		module.nearestMultiple(playerBase.PrimaryPart.Size.X / 2 + chunkCenterX, Gamerules.BlockSize)
	local minZ, maxZ =
		module.nearestMultiple(-playerBase.PrimaryPart.Size.Z / 2 + chunkCenterZ, Gamerules.BlockSize),
		module.nearestMultiple(playerBase.PrimaryPart.Size.Z / 2 + chunkCenterZ, Gamerules.BlockSize)
	local averageHeight = module.FlattenArea(chosenChunk, minX, minZ, maxX, maxZ)

	playerBase:PivotTo(
		CFrame.new(chunkCenterX, 1 + averageHeight, chunkCenterZ)
			* CFrame.Angles(0, math.rad(math.round(math.random(-180, 180) / 90) * 90), 0)
	)
	playerBase:SetAttribute("Chunk", chosenChunk.Name)
	playerBase.Parent = workspace.World.Bases
	return playerBase
end

return module
