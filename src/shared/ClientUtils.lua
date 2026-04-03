--// Client Utilities Module by @MarwanVRG4

local module = {}

module.CoreTag = "CoreUI"
module.PlaceholderTag = "PlaceholderUI"

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local RepStorage = game:GetService("ReplicatedStorage")

local ButtonTI = TweenInfo.new(0.1,Enum.EasingStyle.Linear)
local hoverSizeMulti, clickSizeMulti= 0.91, 0.84

local NotifTI = TweenInfo.new(0.3,Enum.EasingStyle.Linear,Enum.EasingDirection.In,0,true,0)
local NotifTI2 = TweenInfo.new(0.2,Enum.EasingStyle.Linear)

local menuTI = TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

local showBlur; local hideBlur; local fovShow; local fovHide

local PoppingTI = TweenInfo.new(0.09,Enum.EasingStyle.Sine,Enum.EasingDirection.In,0,true,0)

module.STUDIO_SCREEN_SIZE = Vector2.new(1920, 1080)

local isActive = false -- Any Active State of Interacting with a UI (Prevents Overrides and Interacting with Multiple UIs at same time)
local menuShown = false -- Is Player inside any menu? used to change blur & fov state
local hapticNotif, hapticButton

local SpecialNotifTemplate = RepStorage:WaitForChild("Extra"):WaitForChild("SpecialNotification")
local AnsweredSpecialNotif = Instance.new("BindableEvent")
local PendingSpecialNotif = 0

local ABBREVIATIONS = { "K", "M", "B", "T", "Q"}

local hiddenUIs = {}
local defaultSelectableClasses = {"TextBox","ImageButton","TextButton","ScrollingFrame"} -- Selectable Classes by gamepad (Default Of Roblox)

local function firstAncestorIsGui(frame)
	local currentParent = frame.Parent

	while not currentParent:IsA("ScreenGui") do
		if currentParent:IsA("GuiObject") then
			return false
		end
		currentParent = currentParent.Parent
	end
	return true
end

if RunService:IsClient() then
	showBlur = tweenService:Create(game.Lighting.Blur,menuTI,{Size = 12})
	hideBlur = tweenService:Create(game.Lighting.Blur,menuTI,{Size = 0})
	fovShow = tweenService:Create(workspace.CurrentCamera,menuTI,{FieldOfView = 60})
	fovHide = tweenService:Create(workspace.CurrentCamera,menuTI,{FieldOfView = workspace.CurrentCamera.FieldOfView})
	
	hapticNotif = Instance.new("HapticEffect",workspace)
	hapticNotif.Type = Enum.HapticEffectType.UINotification
	hapticNotif.Position = Vector3.new(0.5,0.5,0)
	hapticNotif.Radius = 1
	
	hapticButton = Instance.new("HapticEffect",workspace)
	hapticButton.Type = Enum.HapticEffectType.UIClick
	hapticButton.Radius = 1
end

module.CurrentFrame = nil -- Updated to the current visible frame

module.CachedFramesData = {
	-- Tweens linked to all the activated interface buttons
}

module.Notify = function(player,text,mode,sound,duration)
	local plrGui = player.PlayerGui if not mode then mode = "Normal" end
	local notif = plrGui:WaitForChild("Main").Notifications.Types[mode]
	local c = notif:Clone()
	c.Visible = true c.Text = text c.Parent = plrGui.Main.Notifications
	if duration then c:SetAttribute("Duration",duration) end 
	if sound then sound:Play() else workspace.Sounds.Notify:Play() end
	if mode == "Error" then hapticNotif:Play() end

	task.spawn(function()
		local Pop = tweenService:Create(c,NotifTI,{Size = UDim2.new(c.Size.X.Scale*1.1, 0, c.Size.Y.Scale*1.1, 0)})
		local ShowText = tweenService:Create(c,NotifTI2,{TextTransparency = 0})
		local ShowStroke = tweenService:Create(c.UIStroke,NotifTI2,{Transparency = 0})
		Pop:Play() ShowText:Play() ShowStroke:Play()
		task.wait(c:GetAttribute("Duration"))
		local HideText = tweenService:Create(c,NotifTI2,{Size = UDim2.new(0,0,0,0), TextTransparency = 1})
		local HideStroke = tweenService:Create(c.UIStroke,NotifTI2,{Transparency = 1})
		HideText:Play() HideStroke:Play()
		HideStroke.Completed:Wait()
		c:Destroy()
	end)
end

module.deactivateHiddenUIs = function(frame, placeholderParent : boolean)
	hiddenUIs[frame] = {} local parent = frame.Parent
	if placeholderParent then parent = parent.Parent end

	for _,obj in pairs(parent:GetChildren()) do
		if obj:IsA("GuiObject") and obj ~= frame and obj ~= frame.Parent and obj.Visible and obj.Interactable and not obj:HasTag(module.CoreTag) then
			obj.Visible = false obj.Interactable = false

			-- Update Selection Mode for Gamepads (Goes through all descendants of UI objects that are deactivated)
			if obj.Selectable then obj.Selectable = false end
			for _,descendant in pairs(obj:GetDescendants()) do
				if table.find(defaultSelectableClasses,descendant.ClassName) and descendant.Selectable then 
					descendant.Selectable = false 
				end
			end

			table.insert(hiddenUIs[frame],obj)
		end
	end
end

module.activateHiddenUIs = function(frame)
	if not hiddenUIs[frame] then return end

	for _,obj in pairs(hiddenUIs[frame]) do
		obj.Visible = true obj.Interactable = true 

		-- Enable Selection Mode for Gamepads on deactivated UIs (Goes through all descendants of UI objects that were deactivated)
		if table.find(defaultSelectableClasses,obj.ClassName) then
			obj.Selectable = true
		end
		for _,descendant in pairs(obj:GetDescendants()) do
			if table.find(defaultSelectableClasses,descendant.ClassName) then 
				descendant.Selectable = true 
			end
		end

	end hiddenUIs[frame] = nil
end

module.Initialize = function(obj)
	local XSize = obj.Size.X
	local YSize = obj.Size.Y
	local resetTween = tweenService:Create(obj,ButtonTI,{Size = UDim2.new(XSize.Scale,XSize.Offset,YSize.Scale,YSize.Offset), Rotation = 0})
	local hoverTween = tweenService:Create(obj,ButtonTI,{Size = UDim2.new(XSize.Scale*hoverSizeMulti, XSize.Offset*hoverSizeMulti, YSize.Scale*hoverSizeMulti, YSize.Offset*hoverSizeMulti), Rotation = 5})
	local clickTween = tweenService:Create(obj,ButtonTI,{Size = UDim2.new(XSize.Scale*clickSizeMulti, XSize.Offset*clickSizeMulti, YSize.Scale*clickSizeMulti, YSize.Offset*clickSizeMulti)})
	if not UIS.TouchEnabled then
		obj.MouseEnter:Connect(function() hoverTween:Play() end)
		obj.MouseLeave:Connect(function() resetTween:Play() end)
	end
	obj.Activated:Connect(function(input)
		clickTween:Play() clickTween.Completed:Wait() resetTween:Play() 
	end)
end

module.ScaleScrollingFrame = function(ScrollingFrame)
	
	ScrollingFrame.ScrollBarThickness *= workspace.CurrentCamera.ViewportSize.Magnitude / module.STUDIO_SCREEN_SIZE.Magnitude
	local UILayout = ScrollingFrame:FindFirstChildWhichIsA("UIGridStyleLayout")

	local OriginalExtraPadding = ScrollingFrame:FindFirstChildWhichIsA("UIPadding")
	local AbsoluteCanvasSize = ScrollingFrame.AbsoluteCanvasSize
	local MinorCorrectionRatio = 0
	
	if UILayout:IsA("UIGridLayout") then
		
		local OriginalPadding, OriginalCellSize = UILayout.CellPadding, UILayout.CellSize
		UILayout.CellSize = UDim2.new(OriginalCellSize.X.Scale,0,0,AbsoluteCanvasSize.Y*OriginalCellSize.Y.Scale)
		UILayout.CellPadding = UDim2.new(OriginalPadding.X.Scale,0,0,AbsoluteCanvasSize.Y*OriginalPadding.Y.Scale)
		MinorCorrectionRatio = UILayout.CellSize.Y.Offset * 0.25

	elseif UILayout:IsA("UIListLayout") then

		if ScrollingFrame.ScrollingDirection == Enum.ScrollingDirection.X then
			UILayout.Padding = UDim.new(0, AbsoluteCanvasSize.X*UILayout.Padding.Scale)
		else
			UILayout.Padding = UDim.new(0, AbsoluteCanvasSize.Y*UILayout.Padding.Scale)
		end

		for _,obj in pairs(ScrollingFrame:GetChildren()) do 
			if obj:IsA("GuiObject") then obj.Size = UDim2.new(0,obj.AbsoluteSize.X,0,obj.AbsoluteSize.Y) end
		end
	end

	ScrollingFrame.UIPadding.PaddingLeft = UDim.new(0,AbsoluteCanvasSize.X*OriginalExtraPadding.PaddingLeft.Scale)
	ScrollingFrame.UIPadding.PaddingTop = UDim.new(0,AbsoluteCanvasSize.Y*OriginalExtraPadding.PaddingTop.Scale)
	ScrollingFrame.UIPadding.PaddingRight = UDim.new(0,AbsoluteCanvasSize.X*OriginalExtraPadding.PaddingRight.Scale)
	ScrollingFrame.UIPadding.PaddingBottom = UDim.new(0,AbsoluteCanvasSize.Y*OriginalExtraPadding.PaddingBottom.Scale)

	if ScrollingFrame.ScrollingDirection == Enum.ScrollingDirection.X then
		ScrollingFrame.CanvasSize = UDim2.new(0,AbsoluteCanvasSize.X + MinorCorrectionRatio,0,0)
	else
		ScrollingFrame.CanvasSize = UDim2.new(0,0,0,AbsoluteCanvasSize.Y + MinorCorrectionRatio)
	end
	
	UILayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if ScrollingFrame.ScrollingDirection == Enum.ScrollingDirection.X then
			ScrollingFrame.CanvasSize = UDim2.new(0,UILayout.AbsoluteContentSize.X * 1.1 + MinorCorrectionRatio,0,0)
		else
			ScrollingFrame.CanvasSize = UDim2.new(0,0,0,UILayout.AbsoluteContentSize.Y * 1.1 + MinorCorrectionRatio)
		end
	end)
end

module.toHumanReadable = function(num)
	if num < 1000 then return tostring(num) end
	local digits = math.floor(math.log10(num)) + 1
	local index = math.min(#ABBREVIATIONS, math.floor((digits - 1) / 3))
	local front = num / math.pow(10, index * 3)
	return string.format("%i%s+", front, ABBREVIATIONS[index])
end

module.roundToFirstDecimal = function(num) return tonumber(string.format("%.1f", num)) end

module.Commas = function(num) return tostring(num):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "") end -- https://devforum.roblox.com/t/how-would-i-make-a-large-number-have-commas/384427/14

module.Seconds = function(seconds) 
	if seconds < 0 then return end -- Client Probably has Local Time broken and not synced
	local mins = math.floor(seconds/60); local hours = math.floor(mins/60); local days = math.floor(hours/24)

	if mins > 0 then seconds -= mins * 60 end 
	if hours > 0 then mins -= hours * 60 end 
	if days > 0 then hours -= days * 24 end 

	if seconds <= 9 then seconds = "0"..seconds end
	if mins <= 9 then mins = "0"..mins end
	if hours <= 9 then hours = "0"..hours end
	if days <= 9 then days = "0"..days end

	return tostring( ((tonumber(days) > 0 and days..":") or "")..( ((tonumber(hours) > 0 or tonumber(days) > 0) and hours..":") or "")..mins..":"..seconds)
end

module.executeVisualAction = function(correspondingFrame, visualAction : boolean, effectOnly : boolean)
	local popTween = module.CachedFramesData[correspondingFrame]
	local placeholderParent = correspondingFrame.Parent:HasTag(module.PlaceholderTag)

	if not popTween then -- correspondingFrame may not have a specific button bound to it, therefore it doesn't have cached data
		local poppingSize = UDim2.new(correspondingFrame.Size.X.Scale * 0.93, 0, correspondingFrame.Size.Y.Scale * 0.93, 0)
		popTween = tweenService:Create(correspondingFrame,PoppingTI,{Size = UDim2.new(poppingSize.X.Scale,0,poppingSize.Y.Scale,0)})
		module.CachedFramesData[correspondingFrame] = popTween
	end

	if correspondingFrame.Visible and visualAction == false then
		local newCurrent = correspondingFrame.Parent
		if placeholderParent then newCurrent = correspondingFrame.Parent.Parent end

		if not effectOnly and newCurrent:IsA("ScreenGui") and menuShown then
			menuShown = false hideBlur:Play() fovHide:Play()
		end

		popTween:Play() popTween.Completed:Wait() correspondingFrame.Visible = false
		if not effectOnly then
			module.activateHiddenUIs(correspondingFrame)
			module.CurrentFrame = newCurrent
		end

	elseif not correspondingFrame.Visible and visualAction then

		if not effectOnly and not correspondingFrame:IsA("ScreenGui") and not menuShown then
			menuShown = true showBlur:Play() fovShow:Play()
		end

		correspondingFrame.Visible = true popTween:Play()
		if not effectOnly then
			module.deactivateHiddenUIs(correspondingFrame, placeholderParent)
			module.CurrentFrame = correspondingFrame
			popTween.Completed:Wait()
		end
	end
end

module.SpecialNotify = function(player,text,isPrompt)
	PendingSpecialNotif += 1

	if PendingSpecialNotif > 1 then 
		local QueuePosition = PendingSpecialNotif
		local ShowEvent = Instance.new("BindableEvent")

		local TurnWaitingCon TurnWaitingCon = AnsweredSpecialNotif.Event:Connect(function()
			QueuePosition -= 1 if QueuePosition == 1 then
				ShowEvent:Fire() TurnWaitingCon:Disconnect()
			end
		end)

		ShowEvent.Event:Wait()
	end

	local plrGui = player.PlayerGui
	local notif = SpecialNotifTemplate:Clone()
	local answer

	local function answerFunc()
		PendingSpecialNotif -= 1
		AnsweredSpecialNotif:Fire()
	end

	if isPrompt then
		notif.Yes.Visible = true
		notif.No.Visible = true

		notif.No.Activated:Once(function()
			notif.Yes.Interactable = false
			answer = false
			answerFunc()
		end)
		notif.Yes.Activated:Once(function()
			notif.No.Interactable = false
			answer = true
			answerFunc()
		end)
	else
		notif.Close.Visible = true
		notif.Close.Activated:Once(answerFunc)
	end

	notif.Title.Text = text
	notif.Parent = plrGui.Main

	workspace.Sounds.Pop:Play()
	module.executeVisualAction(notif, true, true)

	AnsweredSpecialNotif.Event:Wait() -- Wait for Answer from Player

	module.executeVisualAction(notif,false, true)
	notif:Destroy()

	return answer
end

module.ActivateButton = function(button, correspondingFrame, visualAction : boolean, effectOnly : boolean)
	button.Activated:Connect(function() 
		if isActive then return end; isActive = true; hapticButton:Play()

		if not module.CurrentFrame:IsA("ScreenGui") and visualAction and firstAncestorIsGui(correspondingFrame) then
			if not firstAncestorIsGui(module.CurrentFrame) then 
				isActive = false return -- If the CurrentFrame is under a Frame and not ScreenGui, then dont do anything
			end
			module.executeVisualAction(module.CurrentFrame, false, false)
		end
		module.executeVisualAction(correspondingFrame, visualAction, effectOnly)
		isActive = false
	end)
end

return module