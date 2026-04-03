--// Data Module for Stranded Farmers by @MarwanVRG4

local module = {}

local DSS = game:GetService("DataStoreService")
local MSS = game:GetService("MemoryStoreService")

local MainDataStore = DSS:GetDataStore("MainDataStoreRELEASE")

local activeProcesses = 0 
local maxExpire = 86400 * 45

module.ControlServer = false
module.MainHashMap = MSS:GetHashMap("Main")

module.CrownRaffleMap = MSS:GetHashMap("CrownRaffle")
module.DailyRaffleMap = MSS:GetHashMap("DailyRaffle")
module.SmallRaffleMap = MSS:GetHashMap("SmallRaffle")

function module.Create(class,name,parent)
	local value = Instance.new(class)
	value.Name = name; value.Parent = parent
	return value
end

function module.Store(key,value)
	activeProcesses += 1
	local success, errorMessage = pcall(function() return MainDataStore:SetAsync(key, value) end)
	activeProcesses -= 1
	if success then return success else print(errorMessage) end
end

function module.Retrieve(key)
	activeProcesses += 1
	local success, data = pcall(function() return MainDataStore:GetAsync(key) end)
	activeProcesses -= 1
	if success then return data, true else print(data) end
end

function module.MemoryStore(key,value,expire,map)
	activeProcesses += 1
	local success, errorMessage = pcall(function() return map:SetAsync(key,value,expire or maxExpire) end)
	activeProcesses -= 1
	if success then return success else print(errorMessage) end
end

function module.MemoryRetrieve(key,map)
	activeProcesses += 1
	local success, data = pcall(function() return map:GetAsync(key) end)
	activeProcesses -= 1
	if success then return data, true else print(data) end
end

function module.MemoryRemove(key,map)
	activeProcesses += 1; pcall(function() map:RemoveAsync(key) end); activeProcesses -= 1
end

function module.Load(player)
	local data, success = module.Retrieve(player.UserId)
	if not success then
		player:Kick("Error While Loading Data! Please Rejoin!")
		return false
	end

	activeProcesses += 1

	local leaderstats = module.Create("Folder","leaderstats",player)
	local Cash = module.Create("IntValue","Cash",leaderstats)
	local Minimap = module.Create("BoolValue","Minimap",player)
	local Gingerbreads = module.Create("IntValue","Gingerbreads",player)
	
	local Index = module.Create("Folder","Index",player)
	local Items = module.Create("Folder","Items",player)
	
	local Plants = module.Create("Folder","Plants",player)
	for i = 1,8 do module.Create("IntValue","Level",module.Create("StringValue",i,Plants)) end
	
	local Growth = module.Create("Folder","Growth",player)
	for i = 1,4 do module.Create("StringValue","Occupant",module.Create("IntValue",i,Growth)) end

	local Scouts = module.Create("Folder","Scouts",player)
	local ScoutStorage = module.Create("IntValue","ScoutStorage",player)
	local ScoutAutoDelete = module.Create("StringValue","ScoutAutoDelete",player)

	module.Create("BoolValue","MerchantStocks",player)

	local RaffleQuests = module.Create("Folder","RaffleQuests",player)
	module.Create("IntValue","Progress",module.Create("StringValue","Easy",RaffleQuests))
	module.Create("IntValue","Progress",module.Create("StringValue","Medium",RaffleQuests))
	module.Create("IntValue","Progress",module.Create("StringValue","Hard",RaffleQuests))
	
	local RaffleRewards = module.Create("Folder","RaffleRewards",player)
	local SmallRaffleTickets = module.Create("IntValue","SmallRaffleTickets",player)
	local DailyRaffleTickets = module.Create("IntValue","DailyRaffleTickets",player)
	local CrownRaffleTickets = module.Create("IntValue","CrownRaffleTickets",player)
	
	local DailyRewards = module.Create("Folder","DailyRewards",player)
	local DailyStreak = module.Create("IntValue","DailyStreak",player)
	DailyStreak.Value = 0; DailyStreak:SetAttribute("LastUpdate",os.time())
	
	local Settings = module.Create("Folder","Settings",player)
	module.Create("BoolValue","Ambience",Settings).Value = true
	module.Create("BoolValue","LowQuality",Settings)
	
	local FuseMachine = module.Create("BoolValue","FuseMachine",player)
	local Composter = module.Create("BoolValue","Composter",player)

	local Stamina = module.Create("IntValue","Stamina",player)
	Stamina.Value = 100
	
	local MeteoriteDamage = module.Create("IntValue","MeteoriteDamage",player)
	MeteoriteDamage.Value = 1
	
	local MeteorShards = module.Create("IntValue","MeteorShards",player)

	if data then
		data = module.ReformatData(data) -- Scan for any old changes that need to be changed

		Cash.Value = data.Cash; MeteorShards.Value = data.MeteorShards
		Minimap.Value = data.Minimap
		Gingerbreads.Value = data.Gingerbreads
		ScoutAutoDelete.Value = data.ScoutAutoDelete
		Stamina.Value = data.Stamina
		MeteoriteDamage.Value = data.MeteoriteDamage
		player:SetAttribute("FirstReveal",data.FirstReveal)
		player:SetAttribute("GroupReward",data.GroupReward)
		player:SetAttribute("CodesRedeemed",data.CodesRedeemed)
		player:SetAttribute("StarterPack",data.StarterPack)
		player:SetAttribute("FirstJoined",data.FirstJoined)
		
		DailyStreak.Value = data.DailyStreak[1]; DailyStreak:SetAttribute("LastUpdate",data.DailyStreak[2])
		FuseMachine.Value = data.FuseMachine[1]; FuseMachine:SetAttribute("Fusion",data.FuseMachine[2])
		Composter.Value = data.Composter[1]; Composter:SetAttribute("Finish",data.Composter[2])
		
		SmallRaffleTickets.Value = data.SmallRaffleTickets[1]; SmallRaffleTickets:SetAttribute("Expire",data.SmallRaffleTickets[2])
		DailyRaffleTickets.Value = data.DailyRaffleTickets[1]; DailyRaffleTickets:SetAttribute("Expire",data.DailyRaffleTickets[2])
		CrownRaffleTickets.Value = data.CrownRaffleTickets
		
		for _,indexData in pairs(data.Index) do module.Create("BoolValue",indexData[1],Index):SetAttribute("Enchanted",indexData[2]) end
		
		for pot,potData in pairs(data.Plants) do
			if not Plants:FindFirstChild(pot) then module.Create("IntValue","Level",module.Create("StringValue",pot,Plants)) end -- Extra Slots 
			Plants[pot].Value = potData.Plant; Plants[pot]:SetAttribute("Enchanted",potData.Enchanted); Plants[pot]:SetAttribute("Soil",potData.Soil);
			Plants[pot].Level.Value = potData.Level 
		end
		
		for pot,growthData in pairs(data.Growth) do
			if not Growth:FindFirstChild(pot) then module.Create("StringValue","Occupant",module.Create("IntValue",pot,Growth)) end -- Extra Slots 
			Growth[pot].Value = growthData.Time; Growth[pot].Occupant:SetAttribute("Enchanted",growthData.Enchanted)
			Growth[pot].Occupant.Value = growthData.Name 
		end
		
		for _,itemData in pairs(data.Backpack) do 
			local itemValue = module.Create("ObjectValue",itemData[1],Items)
			for name,value in pairs(itemData[2]) do itemValue:SetAttribute(name,value) end
		end
		
		for slot,scoutData in pairs(data.Scouts) do
			local scout = module.Create("StringValue",slot,Scouts); scout.Value = scoutData.Name
			module.Create("IntValue","Level",scout).Value = scoutData.Level
			module.Create("BoolValue","Enabled",scout).Value = scoutData.Enabled
		end
		
		for setting,value in pairs(data.Settings) do Settings[setting].Value = value end
		
		for _,seed in pairs(data.ScoutStorage) do module.Create("StringValue",seed,ScoutStorage) end
		ScoutStorage.Value = data.ScoutStorageLevel
		
		for name,questData in pairs(data.RaffleQuests) do
			RaffleQuests[name].Value = questData.Value
			RaffleQuests[name].Progress.Value = questData.Progress
		end
		
		for raffleName,rewards in pairs(data.RaffleRewards) do
			local rewardsFolder = module.Create("Folder",raffleName,RaffleRewards)
			for _,reward in pairs(rewards) do module.Create("BoolValue",reward,rewardsFolder) end
		end
		
		for rewardDate, claimed in pairs(data.DailyRewards) do
			module.Create("BoolValue",rewardDate,DailyRewards).Value = claimed
		end
		
		for _,boostData in pairs(data.CashBoosts) do
			local boost = module.Create("IntValue","Boost",player.leaderstats.Cash)
			boost:SetAttribute("Boost",boostData[1]); boost.Value = boostData[2]
		end
		
		for _,effectData in pairs(data.Effects) do
			module.Create("IntValue",effectData[1],player.Effects).Value = effectData[2]
		end
	else
		player:SetAttribute("Tutorial",true)
		player:SetAttribute("FirstJoined",os.time())
		for i = 1,7 do module.Create("BoolValue", os.time() + (86400 * i), DailyRewards) end
	end
	
	activeProcesses -= 1
	return data
end

function module.Save(player)	
	activeProcesses += 1
	local data = {}

	data.Cash = player.leaderstats.Cash.Value
	data.MeteorShards = player.MeteorShards.Value; data.MeteoriteDamage = player.MeteoriteDamage.Value
	data.Stamina = player.Stamina.Value
	data.Minimap = player.Minimap.Value
	data.Gingerbreads = player.Gingerbreads.Value
	data.FirstReveal = player:GetAttribute("FirstReveal")
	data.GroupReward = player:GetAttribute("GroupReward")
	data.CodesRedeemed = player:GetAttribute("CodesRedeemed")
	data.StarterPack = player:GetAttribute("StarterPack")
	data.FirstJoined = player:GetAttribute("FirstJoined")
	
	data.DailyStreak = {player.DailyStreak.Value,player.DailyStreak:GetAttribute("LastUpdate")}
	data.FuseMachine = {player.FuseMachine.Value,player.FuseMachine:GetAttribute("Fusion")}
	data.Composter = {player.Composter.Value,player.Composter:GetAttribute("Finish")}
	
	data.SmallRaffleTickets = {player.SmallRaffleTickets.Value,player.SmallRaffleTickets:GetAttribute("Expire")}
	data.DailyRaffleTickets = {player.DailyRaffleTickets.Value,player.DailyRaffleTickets:GetAttribute("Expire")}
	data.CrownRaffleTickets = player.CrownRaffleTickets.Value
	
	data.ScoutAutoDelete = player.ScoutAutoDelete.Value
	
	data.Index = {}; for _,value in pairs(player.Index:GetChildren()) do
		table.insert(data.Index,{value.Name,value:GetAttribute("Enchanted")})
	end
	
	data.Growth = {}; for _,pot in pairs(player.Growth:GetChildren()) do
		data.Growth[pot.Name] = {Time = pot.Value, Name = pot.Occupant.Value, Enchanted = pot.Occupant:GetAttribute("Enchanted")}
	end
	
	data.Plants = {}; for _,pot in pairs(player.Plants:GetChildren()) do
		data.Plants[pot.Name] = {Level = pot.Level.Value, Plant = pot.Value, Enchanted = pot:GetAttribute("Enchanted"), Soil = pot:GetAttribute("Soil")}
	end
	
	data.Backpack = {}; for _,tool in pairs(player.Items:GetChildren()) do
		table.insert(data.Backpack,{tool.Name,tool:GetAttributes()})
	end

	data.Scouts = {}; for _,scout in pairs(player.Scouts:GetChildren()) do
		data.Scouts[scout.Name] = {Name = scout.Value, Level = scout.Level.Value, Enabled = scout.Enabled.Value}
	end
	
	data.ScoutStorageLevel = player.ScoutStorage.Value
	
	data.ScoutStorage = {}; for _,seed in pairs(player.ScoutStorage:GetChildren()) do
		table.insert(data.ScoutStorage,seed.Name)
	end

	data.Settings = {}; for _,setting in pairs(player.Settings:GetChildren()) do
		data.Settings[setting.Name] = setting.Value
	end

	data.RaffleQuests = {}; for _,quest in pairs(player.RaffleQuests:GetChildren()) do
		data.RaffleQuests[quest.Name] = {Value = quest.Value, Progress = quest.Progress.Value}
	end
	
	data.RaffleRewards = {}; for _,rewardsFolder in pairs(player.RaffleRewards:GetChildren()) do
		data.RaffleRewards[rewardsFolder.Name] = {}; for _,reward in pairs(rewardsFolder:GetChildren()) do
			table.insert(data.RaffleRewards[rewardsFolder.Name],reward.Name)
		end
	end

	data.DailyRewards = {}; for _,reward in pairs(player.DailyRewards:GetChildren()) do
		data.DailyRewards[tonumber(reward.Name)] = reward.Value
	end

	data.CashBoosts = {}; for _,obj in pairs(player.leaderstats.Cash:GetChildren()) do
		if obj.Name == "Boost" then table.insert(data.CashBoosts,{obj:GetAttribute("Boost"),obj.Value}) end
	end

	data.Effects = {}; for _,effect in pairs(player.Effects:GetChildren()) do
		table.insert(data.Effects,{effect.Name, effect.Value})
	end

	data.LastJoined = os.time()

	module.Store(player.UserId, data)
	activeProcesses -= 1
end

function module.ReformatData(data) -- For Updates that Change the Structure of the Player's Data
	if not data.Settings then data.Settings = {Ambience = true, LowQuality = false} end
	if not data.FirstJoined then data.FirstJoined = 0 end
	if not data.Gingerbreads then data.Gingerbreads = 0 end
	
	if not data.RaffleQuests then 
		data.RaffleQuests = {
			Easy = {Value = "", Progress = 0},
			Medium = {Value = "", Progress = 0},
			Hard = {Value = "", Progress = 0},
		}
		data.SmallRaffleTickets = {0,0}
		data.DailyRaffleTickets = {0,0}
		data.CrownRaffleTickets = 0
		data.RaffleRewards = {}
	end
	
	if not data.ScoutAutoDelete then data.ScoutAutoDelete = "" end
	
	if not data.DailyRewards then 
		data.DailyStreak = {0,os.time()}; data.DailyRewards = {
		[os.time() + 86400] = false, [os.time() + (86400 * 2)] = false, 
		[os.time() + (86400 * 3)] = false, [os.time() + (86400 * 4)] = false, 
		[os.time() + (86400 * 5)] = false, [os.time() + (86400 * 6)] = false, 
		[os.time() + (86400 * 7)] = false,
	} end
	
	if not data.FuseMachine then data.FuseMachine = {false} end
	
	for _,itemData in pairs(data.Backpack) do -- Old Backpack Structure (Pre V2.0)
		if type(itemData[2]) ~= "table" then 
			local newBackpack = {}
			for _,itemData in pairs(data.Backpack) do table.insert(newBackpack,{itemData[1],{Uses = itemData[2]}}) end
			data.Backpack = newBackpack; break
		end 
	end
	
	for _,indexData in pairs(data.Index) do -- Old Index Structure (Pre V2.0)
		if type(indexData) == "string" then
			local newIndex = {}
			for _,itemData in pairs(data.Index) do table.insert(newIndex,{itemData}) end
			data.Index = newIndex; break
		end
	end
	
	if not data.CashBoosts then data.CashBoosts = {} end
	if not data.Effects then data.Effects = {} end
	
	if not data.Composter then data.Composter = {false} end
	
	if not data.Stamina then
		data.MeteoriteDamage = 1
		data.Stamina = 100
		data.MeteorShards = 0
	end
	
	return data
end

game:BindToClose(function() while activeProcesses > 0 do task.wait(1) end end)

return module