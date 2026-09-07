local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer

local Base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Decode(Data)
	Data = Data:gsub("[^" .. Base64Chars .. "=]", "")

	return (Data:gsub(".", function(Character)
		if Character == "=" then
			return ""
		end

		local Value = Base64Chars:find(Character, 1, true) - 1
		local Bits = ""

		for Index = 6, 1, -1 do
			Bits = Bits .. (Value % 2 ^ Index - Value % 2 ^ (Index - 1) > 0 and "1" or "0")
		end

		return Bits
	end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(Byte)
		if #Byte ~= 8 then
			return ""
		end

		local Value = 0

		for Index = 1, 8 do
			if Byte:sub(Index, Index) == "1" then
				Value = Value + 2 ^ (8 - Index)
			end
		end

		return string.char(Value)
	end))
end

local function AssetId(Value)
	if not Value then
		return 0
	end

	if type(Value) == "number" then
		return Value
	end

	return tonumber(tostring(Value):match("%d+")) or 0
end

local function AppendAccessory(Description, Property, ID)
	local Current = ""

	pcall(function()
		Current = Description[Property]
	end)

	if Current == nil then
		return
	end

	Current = tostring(Current)

	if Current == "" then
		Description[Property] = tostring(ID)
	else
		Description[Property] = Current .. "," .. tostring(ID)
	end
end

local CatalogProperties = {}

local function MapAssetType(Name, Property)
	local Success, Item = pcall(function()
		return Enum.AssetType[Name]
	end)

	if Success and Item then
		CatalogProperties[Item.Value] = Property
	end
end

MapAssetType("Hat", "HatAccessory")
MapAssetType("HairAccessory", "HairAccessory")
MapAssetType("FaceAccessory", "FaceAccessory")
MapAssetType("NeckAccessory", "NeckAccessory")
MapAssetType("ShoulderAccessory", "ShouldersAccessory")
MapAssetType("FrontAccessory", "FrontAccessory")
MapAssetType("BackAccessory", "BackAccessory")
MapAssetType("WaistAccessory", "WaistAccessory")

MapAssetType("TShirtAccessory", "TShirtAccessory")
MapAssetType("ShirtAccessory", "ShirtAccessory")
MapAssetType("PantsAccessory", "PantsAccessory")
MapAssetType("JacketAccessory", "JacketAccessory")
MapAssetType("SweaterAccessory", "SweaterAccessory")
MapAssetType("ShortsAccessory", "ShortsAccessory")
MapAssetType("LeftShoeAccessory", "LeftShoeAccessory")
MapAssetType("RightShoeAccessory", "RightShoeAccessory")
MapAssetType("DressSkirtAccessory", "DressSkirtAccessory")

local function ApplyCatalogItem(Description, ID)
	ID = tonumber(ID)

	if not ID or ID <= 0 then
		return
	end

	local Success, Info = pcall(function()
		return MarketplaceService:GetProductInfo(ID, Enum.InfoType.Asset)
	end)

	if not Success or not Info then
		return
	end

	local AssetType = Info.AssetTypeId

	if CatalogProperties[AssetType] then
		pcall(function()
			AppendAccessory(
				Description,
				CatalogProperties[AssetType],
				ID
			)
		end)

		return
	end

	local function IsType(Name)
		local SuccessType, EnumItem = pcall(function()
			return Enum.AssetType[Name]
		end)

		return SuccessType
		and EnumItem
		and AssetType == EnumItem.Value
	end

	if IsType("Shirt") then
		Description.Shirt = ID

	elseif IsType("Pants") then
		Description.Pants = ID

	elseif IsType("TShirt") then
		Description.GraphicTShirt = ID

	elseif IsType("Face") then
		Description.Face = ID

	elseif IsType("Head") then
		Description.Head = ID

	elseif IsType("Torso") then
		Description.Torso = ID

	elseif IsType("LeftArm") then
		Description.LeftArm = ID

	elseif IsType("RightArm") then
		Description.RightArm = ID

	elseif IsType("LeftLeg") then
		Description.LeftLeg = ID

	elseif IsType("RightLeg") then
		Description.RightLeg = ID

	elseif IsType("ClimbAnimation") then
		Description.ClimbAnimation = ID

	elseif IsType("FallAnimation") then
		Description.FallAnimation = ID

	elseif IsType("IdleAnimation") then
		Description.IdleAnimation = ID

	elseif IsType("JumpAnimation") then
		Description.JumpAnimation = ID

	elseif IsType("RunAnimation") then
		Description.RunAnimation = ID

	elseif IsType("SwimAnimation") then
		Description.SwimAnimation = ID

	elseif IsType("WalkAnimation") then
		Description.WalkAnimation = ID
	end
end

local function ComponentsToCFrame(Data)
	if type(Data) ~= "table" or #Data < 12 then
		return CFrame.new()
	end

	return CFrame.new(
		Data[1],
		Data[2],
		Data[3],

		Data[4],
		Data[5],
		Data[6],

		Data[7],
		Data[8],
		Data[9],

		Data[10],
		Data[11],
		Data[12]
	)
end

local function Vector3FromTable(Data, Default)
	if type(Data) ~= "table" then
		return Default
	end

	return Vector3.new(
		tonumber(Data[1]) or Default.X,
		tonumber(Data[2]) or Default.Y,
		tonumber(Data[3]) or Default.Z
	)
end

local function FindAttachment(Character, Name)
	if not Name or Name == "" then
		return nil
	end

	for _, Object in ipairs(Character:GetDescendants()) do
		if Object:IsA("Attachment") and Object.Name == Name then
			return Object
		end
	end

	return nil
end

local function CreateRawAccessory(Character, Data)
	if type(Data) ~= "table" then
		return
	end

	local Accessory = Instance.new("Accessory")
	Accessory.Name = Data.name or "StoredAccessory"

	local Handle = Instance.new("MeshPart")
	Handle.Name = "Handle"
	Handle.CanCollide = false
	Handle.CanTouch = false
	Handle.CanQuery = false
	Handle.Massless = true

	if Data.meshId then
		pcall(function()
			Handle.MeshId = tostring(Data.meshId)
		end)
	end

	if Data.textureId then
		pcall(function()
			Handle.TextureID = tostring(Data.textureId)
		end)
	end

	if Data.size then
		Handle.Size = Vector3FromTable(
			Data.size,
			Vector3.new(1, 1, 1)
		)
	end

	local HandleAttachment

	if Data.attachment then
		HandleAttachment = Instance.new("Attachment")
		HandleAttachment.Name = Data.attachment

		if Data.attachmentCFrame then
			HandleAttachment.CFrame = ComponentsToCFrame(
				Data.attachmentCFrame
			)
		end

		HandleAttachment.Parent = Handle
	end

	Handle.Parent = Accessory

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if Humanoid and HandleAttachment then
		local Success = pcall(function()
			Humanoid:AddAccessory(Accessory)
		end)

		if Success then
			return
		end
	end

	Accessory.Parent = Character

	local TargetAttachment = FindAttachment(
		Character,
		Data.attachment
	)

	local TargetPart

	if TargetAttachment then
		TargetPart = TargetAttachment.Parent
	elseif Data.targetPart then
		TargetPart = Character:FindFirstChild(Data.targetPart)
	else
		TargetPart =
			Character:FindFirstChild("Head")
			or Character:FindFirstChild("UpperTorso")
			or Character:FindFirstChild("Torso")
	end

	if not TargetPart or not TargetPart:IsA("BasePart") then
		return
	end

	local Weld = Instance.new("Weld")
	Weld.Name = "AccessoryWeld"
	Weld.Part0 = Handle
	Weld.Part1 = TargetPart

	if Data.handleCFrame then
		Weld.C0 = ComponentsToCFrame(Data.handleCFrame)
	end

	if Data.targetCFrame then
		Weld.C1 = ComponentsToCFrame(Data.targetCFrame)
	elseif TargetAttachment then
		Weld.C1 = TargetAttachment.CFrame
	end

	Weld.Parent = Handle
end

local function ApplyDictionary(Description, Dictionary)
	if type(Dictionary) ~= "table" then
		return
	end

	for Property, Value in pairs(Dictionary) do
		pcall(function()
			Description[Property] = Value
		end)
	end
end

local function ApplyDirectCharacterData(Character, Avatar)
	if type(Avatar.partSizes) == "table" then
		for PartName, Size in pairs(Avatar.partSizes) do
			local Part = Character:FindFirstChild(PartName)

			if Part and Part:IsA("BasePart") then
				Part.Size = Vector3FromTable(
					Size,
					Part.Size
				)
			end
		end
	end

	if type(Avatar.partCFrames) == "table" then
		for PartName, CFrameData in pairs(Avatar.partCFrames) do
			local Part = Character:FindFirstChild(PartName)

			if Part and Part:IsA("BasePart") then
				Part.CFrame = ComponentsToCFrame(CFrameData)
			end
		end
	end

	if type(Avatar.properties) == "table" then
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			for Property, Value in pairs(Avatar.properties) do
				pcall(function()
					Humanoid[Property] = Value
				end)
			end
		end
	end
end

local function StopCurrentAnimations(Character)
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")

	if not Humanoid then
		return
	end

	local Animator = Humanoid:FindFirstChildOfClass("Animator")

	if not Animator then
		return
	end

	for _, Track in ipairs(Animator:GetPlayingAnimationTracks()) do
		pcall(function()
			Track:Stop(0)
		end)
	end
end

local function ApplyRuntimeAnimations(Character, Animations)
	if type(Animations) ~= "table" then
		return
	end

	local Animate = Character:FindFirstChild("Animate")

	if not Animate then
		return
	end

	for _, Object in ipairs(Animate:GetDescendants()) do
		if Object:IsA("Animation") then
			local Value =
				Animations[Object.Name]
				or Animations[Object.Parent and Object.Parent.Name or ""]

			if Value then
				Object.AnimationId =
					"rbxassetid://" .. tostring(AssetId(Value))
			end
		end
	end
end

local function DecodeItem(Item)
	if type(Item) ~= "table" then
		return nil
	end

	if type(Item.data) ~= "string" then
		return nil
	end

	return Base64Decode(Item.data)
end

local function LoadAvatar()
	if not isfile or not readfile then
		return nil
	end

	if not isfile("avatars.json") then
		return nil
	end

	local Success, Result = pcall(function()
		return HttpService:JSONDecode(
			readfile("avatars.json")
		)
	end)

	if not Success or type(Result) ~= "table" then
		return nil
	end

	local AvatarName = Result.selected

	if
	type(Result.avatars) ~= "table"
	or not AvatarName
	then
		return nil
	end

	return Result.avatars[AvatarName]
end

local function ApplyAvatar()
	local Avatar = LoadAvatar()

	if not Avatar then
		return
	end

	local Character =
		Player.Character
		or Player.CharacterAdded:Wait()

	local Humanoid =
		Character:WaitForChild("Humanoid")

	local Description

	local Success = pcall(function()
		Description =
			Humanoid:GetAppliedDescription()
	end)

	if not Success or not Description then
		Description = Instance.new("HumanoidDescription")
	end

	ApplyDictionary(Description, Avatar.body)
	ApplyDictionary(Description, Avatar.clothing)
	ApplyDictionary(Description, Avatar.animations)
	ApplyDictionary(Description, Avatar.scales)

	local RawItems = {}

	if type(Avatar.items) == "table" then
		for _, Item in ipairs(Avatar.items) do
			if Item.type == "catalog" then
				local Decoded = DecodeItem(Item)

				if Decoded then
					ApplyCatalogItem(
						Description,
						tonumber(Decoded)
					)
				end

			elseif Item.type == "raw" then
				local Decoded = DecodeItem(Item)

				if Decoded then
					local DecodeSuccess, RawData =
						pcall(function()
							return HttpService:JSONDecode(
								Decoded
							)
						end)

					if DecodeSuccess and RawData then
						table.insert(
							RawItems,
							RawData
						)
					end
				end
			end
		end
	end

	pcall(function()
		Humanoid:ApplyDescription(Description)
	end)

	task.wait()

	Character =
		Player.Character
		or Character

	for _, RawData in ipairs(RawItems) do
		CreateRawAccessory(
			Character,
			RawData
		)
	end

	ApplyDirectCharacterData(
		Character,
		Avatar
	)

	ApplyRuntimeAnimations(
		Character,
		Avatar.runtimeAnimations
	)

	StopCurrentAnimations(Character)
end

ApplyAvatar()

Player.CharacterAdded:Connect(function()
	task.wait(1)
	ApplyAvatar()
end)