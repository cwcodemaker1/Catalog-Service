local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Environment = getgenv and getgenv() or _G

local Base64Chars =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local JSON_URLS = {
	"https://raw.githubusercontent.com/cwcodemaker1/Catalog-Service/main/avatars.json",
	"https://raw.githubusercontent.com/cwcodemaker1/Catalog-Service/main/src/avatars.json"
}

local function Base64Decode(Data)
	Data = tostring(Data or "")
	Data = Data:gsub("[^" .. Base64Chars .. "=]", "")

	return (
		Data:gsub(".", function(Character)
			if Character == "=" then
				return ""
			end

			local Position =
				Base64Chars:find(
					Character,
					1,
					true
				)

			if not Position then
				return ""
			end

			local Value = Position - 1
			local Bits = ""

			for Index = 6, 1, -1 do
				Bits ..=
					Value % 2 ^ Index
						- Value % 2 ^ (Index - 1)
						> 0
					and "1"
					or "0"
			end

			return Bits
		end):gsub(
			"%d%d%d?%d?%d?%d?%d?%d?",
			function(Byte)
				if #Byte ~= 8 then
					return ""
				end

				local Value = 0

				for Index = 1, 8 do
					if Byte:sub(Index, Index) == "1" then
						Value += 2 ^ (8 - Index)
					end
				end

				return string.char(Value)
			end
		)
	)
end

local function DecodeObject(Data)
	if type(Data) ~= "string" then
		return nil
	end

	local Success, Result =
		pcall(function()
			return HttpService:JSONDecode(
				Base64Decode(Data)
			)
		end)

	if Success then
		return Result
	end

	return nil
end

local function ToVector3(Data, Default)
	Default = Default or Vector3.zero

	if type(Data) ~= "table" then
		return Default
	end

	return Vector3.new(
		tonumber(Data[1]) or Default.X,
		tonumber(Data[2]) or Default.Y,
		tonumber(Data[3]) or Default.Z
	)
end

local function ToColor3(Data)
	if type(Data) ~= "table" then
		return Color3.new(1, 1, 1)
	end

	return Color3.new(
		tonumber(Data[1]) or 1,
		tonumber(Data[2]) or 1,
		tonumber(Data[3]) or 1
	)
end

local function ToCFrame(Data)
	if type(Data) ~= "table" or #Data < 12 then
		return CFrame.new()
	end

	return CFrame.new(
		tonumber(Data[1]) or 0,
		tonumber(Data[2]) or 0,
		tonumber(Data[3]) or 0,

		tonumber(Data[4]) or 1,
		tonumber(Data[5]) or 0,
		tonumber(Data[6]) or 0,

		tonumber(Data[7]) or 0,
		tonumber(Data[8]) or 1,
		tonumber(Data[9]) or 0,

		tonumber(Data[10]) or 0,
		tonumber(Data[11]) or 0,
		tonumber(Data[12]) or 1
	)
end

local function LoadData()
	if type(readfile) == "function" then
		local Files = {
			"avatars.json",
			"Catalog-Service/avatars.json",
			"Catalog-Service/src/avatars.json"
		}

		for _, Path in ipairs(Files) do
			local Exists = true

			if type(isfile) == "function" then
				Exists = isfile(Path)
			end

			if Exists then
				local Success, Result =
					pcall(function()
						return HttpService:JSONDecode(
							readfile(Path)
						)
					end)

				if
					Success
					and type(Result) == "table"
					and type(Result.avatars) == "table"
				then
					return Result
				end
			end
		end
	end

	for _, URL in ipairs(JSON_URLS) do
		local Success, Result =
			pcall(function()
				return HttpService:JSONDecode(
					game:HttpGet(
						URL
							.. "?v="
							.. tostring(os.time())
							.. tostring(math.random(1, 999999))
					)
				)
			end)

		if
			Success
			and type(Result) == "table"
			and type(Result.avatars) == "table"
		then
			return Result
		end
	end

	return nil
end

local function GetAvatar(Data, AvatarName)
	if
		type(Data) ~= "table"
		or type(Data.avatars) ~= "table"
	then
		return nil
	end

	if
		type(AvatarName) == "string"
		and AvatarName ~= ""
	then
		return Data.avatars[AvatarName]
	end

	if
		Data.selected
		and Data.avatars[Data.selected]
	then
		return Data.avatars[Data.selected]
	end

	return nil
end

local R15ToR6 = {
	Head = "Head",

	UpperTorso = "Torso",
	LowerTorso = "Torso",

	LeftUpperArm = "Left Arm",
	LeftLowerArm = "Left Arm",
	LeftHand = "Left Arm",

	RightUpperArm = "Right Arm",
	RightLowerArm = "Right Arm",
	RightHand = "Right Arm",

	LeftUpperLeg = "Left Leg",
	LeftLowerLeg = "Left Leg",
	LeftFoot = "Left Leg",

	RightUpperLeg = "Right Leg",
	RightLowerLeg = "Right Leg",
	RightFoot = "Right Leg",

	HumanoidRootPart = "HumanoidRootPart"
}

local function R6ToR15(
	SourceName,
	AttachmentName
)
	if SourceName == "Head" then
		return "Head"
	end

	if SourceName == "Left Arm" then
		return "LeftUpperArm"
	end

	if SourceName == "Right Arm" then
		return "RightUpperArm"
	end

	if SourceName == "Left Leg" then
		return "LeftUpperLeg"
	end

	if SourceName == "Right Leg" then
		return "RightUpperLeg"
	end

	if SourceName == "HumanoidRootPart" then
		return "HumanoidRootPart"
	end

	if SourceName == "Torso" then
		if AttachmentName then
			if AttachmentName:find("Waist") then
				return "LowerTorso"
			end

			if AttachmentName:find("Hip") then
				return "LowerTorso"
			end
		end

		return "UpperTorso"
	end

	return SourceName
end

local function GetMappedPart(
	Character,
	Humanoid,
	SourceName,
	AttachmentName
)
	local Exact =
		Character:FindFirstChild(
			SourceName
		)

	if
		Exact
		and Exact:IsA("BasePart")
	then
		return Exact
	end

	if Humanoid.RigType == Enum.HumanoidRigType.R6 then
		local Name =
			R15ToR6[SourceName]

		if Name then
			local Part =
				Character:FindFirstChild(
					Name
				)

			if
				Part
				and Part:IsA("BasePart")
			then
				return Part
			end
		end

		return nil
	end

	local Name =
		R6ToR15(
			SourceName,
			AttachmentName
		)

	if Name then
		local Part =
			Character:FindFirstChild(
				Name
			)

		if
			Part
			and Part:IsA("BasePart")
		then
			return Part
		end
	end

	return nil
end

local function BuildSavedBodyMap(Avatar)
	local Result = {}

	if type(Avatar.bodyParts) ~= "table" then
		return Result
	end

	for _, Entry in ipairs(
		Avatar.bodyParts
	) do
		if
			type(Entry) == "table"
			and Entry.type == "actualBodyPart"
			and Entry.data
		then
			local Data =
				DecodeObject(
					Entry.data
				)

			if
				Data
				and Data.name
			then
				Result[Data.name] = Data
			end
		end
	end

	return Result
end

local function FindSavedAttachment(
	SavedBodyMap,
	AttachmentName
)
	for PartName, PartData in pairs(
		SavedBodyMap
	) do
		if type(PartData.attachments) == "table" then
			for _, Attachment in ipairs(
				PartData.attachments
			) do
				if
					Attachment.name
					== AttachmentName
				then
					return
						PartName,
						PartData,
						Attachment
				end
			end
		end
	end

	return nil
end

local function FindCurrentAttachment(
	Character,
	Name,
	Ignore
)
	for _, Object in ipairs(
		Character:GetDescendants()
	) do
		if
			Object:IsA("Attachment")
			and Object.Name == Name
			and (
				not Ignore
				or not Object:IsDescendantOf(
					Ignore
				)
			)
		then
			return Object
		end
	end

	return nil
end

local function ApplyAccessoryAttachments(
	Handle,
	Attachments
)
	if type(Attachments) ~= "table" then
		return
	end

	for _, Data in ipairs(
		Attachments
	) do
		if
			Data.name
			and not Data.name:match(
				"RigAttachment$"
			)
		then
			local Attachment =
				Instance.new("Attachment")

			Attachment.Name =
				Data.name

			if Data.cframe then
				Attachment.CFrame =
					ToCFrame(
						Data.cframe
					)

			elseif Data.position then
				Attachment.Position =
					ToVector3(
						Data.position
					)

				if Data.orientation then
					Attachment.Orientation =
						ToVector3(
							Data.orientation
						)
				end
			end

			Attachment.Parent =
				Handle
		end
	end
end

local function CreateWeld(
	Handle,
	TargetPart,
	C0,
	C1
)
	local Existing =
		Handle:FindFirstChild(
			"AccessoryWeld"
		)

	if Existing then
		Existing:Destroy()
	end

	local Weld =
		Instance.new("Weld")

	Weld.Name =
		"AccessoryWeld"

	Weld.Part0 =
		Handle

	Weld.Part1 =
		TargetPart

	Weld.C0 =
		C0

	Weld.C1 =
		C1

	Weld.Parent =
		Handle

	return Weld
end

local function WeldAccessory(
	Character,
	Humanoid,
	Accessory,
	Handle,
	SavedBodyMap
)
	local HandleAttachment =
		Handle:FindFirstChildOfClass(
			"Attachment"
		)

	if not HandleAttachment then
		return
	end

	local AttachmentName =
		HandleAttachment.Name

	local SourcePartName,
	SourcePartData,
	SourceAttachment =
		FindSavedAttachment(
			SavedBodyMap,
			AttachmentName
		)

	if
		SourcePartName
		and SourceAttachment
	then
		local TargetPart =
			GetMappedPart(
				Character,
				Humanoid,
				SourcePartName,
				AttachmentName
			)

		if TargetPart then
			local TargetAttachmentCFrame

			if SourceAttachment.cframe then
				TargetAttachmentCFrame =
					ToCFrame(
						SourceAttachment.cframe
					)

			elseif SourceAttachment.position then
				TargetAttachmentCFrame =
					CFrame.new(
						ToVector3(
							SourceAttachment.position
						)
					)

				if SourceAttachment.orientation then
					local Orientation =
						ToVector3(
							SourceAttachment.orientation
						)

					TargetAttachmentCFrame *=
						CFrame.Angles(
							math.rad(
								Orientation.X
							),
							math.rad(
								Orientation.Y
							),
							math.rad(
								Orientation.Z
							)
						)
				end

			else
				TargetAttachmentCFrame =
					CFrame.new()
			end

			Handle.CFrame =
				TargetPart.CFrame
				* TargetAttachmentCFrame
				* HandleAttachment.CFrame:Inverse()

			CreateWeld(
				Handle,
				TargetPart,
				HandleAttachment.CFrame,
				TargetAttachmentCFrame
			)

			return
		end
	end

	local CurrentAttachment =
		FindCurrentAttachment(
			Character,
			AttachmentName,
			Accessory
		)

	if
		CurrentAttachment
		and CurrentAttachment.Parent
		and CurrentAttachment.Parent:IsA(
			"BasePart"
		)
	then
		local TargetPart =
			CurrentAttachment.Parent

		Handle.CFrame =
			TargetPart.CFrame
			* CurrentAttachment.CFrame
			* HandleAttachment.CFrame:Inverse()

		CreateWeld(
			Handle,
			TargetPart,
			HandleAttachment.CFrame,
			CurrentAttachment.CFrame
		)
	end
end

local function GetMeshScale(
	HandleData,
	MeshData
)
	if
		MeshData.meshSize
		and HandleData.size
	then
		local MeshSize =
			ToVector3(
				MeshData.meshSize
			)

		local Size =
			ToVector3(
				HandleData.size
			)

		if
			MeshSize.X ~= 0
			and MeshSize.Y ~= 0
			and MeshSize.Z ~= 0
		then
			return Vector3.new(
				Size.X / MeshSize.X,
				Size.Y / MeshSize.Y,
				Size.Z / MeshSize.Z
			)
		end
	end

	if MeshData.scale then
		return ToVector3(
			MeshData.scale,
			Vector3.new(1, 1, 1)
		)
	end

	if HandleData.size then
		return ToVector3(
			HandleData.size,
			Vector3.new(1, 1, 1)
		)
	end

	return Vector3.new(
		1,
		1,
		1
	)
end

local function CreateAccessory(
	Character,
	Humanoid,
	Data,
	SavedBodyMap
)
	if
		type(Data) ~= "table"
		or type(Data.handle) ~= "table"
	then
		return
	end

	local HandleData =
		Data.handle

	local Accessory =
		Instance.new("Accessory")

	Accessory.Name =
		Data.name
		or "Accessory"

	if Data.accessoryType then
		pcall(function()
			Accessory.AccessoryType =
				Enum.AccessoryType[
					Data.accessoryType
				]
		end)
	end

	local Handle =
		Instance.new("Part")

	Handle.Name =
		"Handle"

	Handle.Size =
		ToVector3(
			HandleData.size,
			Vector3.new(1, 1, 1)
		)

	Handle.CanCollide = false
	Handle.CanTouch = false
	Handle.CanQuery = false
	Handle.Massless = true

	if HandleData.color then
		Handle.Color =
			ToColor3(
				HandleData.color
			)
	end

	if HandleData.transparency ~= nil then
		Handle.Transparency =
			HandleData.transparency
	end

	if HandleData.reflectance ~= nil then
		Handle.Reflectance =
			HandleData.reflectance
	end

	if HandleData.material then
		pcall(function()
			Handle.Material =
				Enum.Material[
					HandleData.material
				]
		end)
	end

	local MeshData =
		HandleData.mesh

	if
		type(MeshData) == "table"
		and type(MeshData.meshId) == "string"
		and MeshData.meshId ~= ""
	then
		local Mesh =
			Instance.new("SpecialMesh")

		Mesh.MeshType =
			Enum.MeshType.FileMesh

		Mesh.MeshId =
			MeshData.meshId

		Mesh.TextureId =
			MeshData.textureId
			or ""

		Mesh.Scale =
			GetMeshScale(
				HandleData,
				MeshData
			)

		if MeshData.offset then
			Mesh.Offset =
				ToVector3(
					MeshData.offset
				)
		end

		Mesh.Parent =
			Handle
	end

	ApplyAccessoryAttachments(
		Handle,
		HandleData.attachments
	)

	Handle.Parent =
		Accessory

	Accessory.Parent =
		Character

	WeldAccessory(
		Character,
		Humanoid,
		Accessory,
		Handle,
		SavedBodyMap
	)
end

local function ApplyAccessories(
	Character,
	Humanoid,
	Avatar,
	SavedBodyMap
)
	for _, Object in ipairs(
		Character:GetChildren()
	) do
		if Object:IsA("Accessory") then
			Object:Destroy()
		end
	end

	if type(Avatar.accessories) ~= "table" then
		return
	end

	for Index, Entry in ipairs(
		Avatar.accessories
	) do
		if
			type(Entry) == "table"
			and Entry.type
				== "actualAccessory"
			and Entry.data
		then
			local Data =
				DecodeObject(
					Entry.data
				)

			if Data then
				CreateAccessory(
					Character,
					Humanoid,
					Data,
					SavedBodyMap
				)
			end
		end

		if Index % 4 == 0 then
			task.wait()
		end
	end
end

local function ApplyBodyVisuals(
	Character,
	Humanoid,
	SavedBodyMap
)
	for SourceName, Data in pairs(
		SavedBodyMap
	) do
		if
			SourceName
				~= "HumanoidRootPart"
		then
			local Part =
				GetMappedPart(
					Character,
					Humanoid,
					SourceName
				)

			if
				Part
				and Part:IsA("BasePart")
			then
				if Data.color then
					Part.Color =
						ToColor3(
							Data.color
						)
				end

				if Data.reflectance ~= nil then
					Part.Reflectance =
						Data.reflectance
				end

				if Data.material then
					pcall(function()
						Part.Material =
							Enum.Material[
								Data.material
							]
					end)
				end
			end
		end
	end
end

local function ApplyBodyColors(
	Character,
	Avatar
)
	local Data =
		Avatar.bodyColors

	if type(Data) ~= "table" then
		return
	end

	local Colors =
		Character:FindFirstChildOfClass(
			"BodyColors"
		)

	if not Colors then
		Colors =
			Instance.new("BodyColors")

		Colors.Parent =
			Character
	end

	if Data.head then
		Colors.HeadColor3 =
			ToColor3(Data.head)
	end

	if Data.torso then
		Colors.TorsoColor3 =
			ToColor3(Data.torso)
	end

	if Data.leftArm then
		Colors.LeftArmColor3 =
			ToColor3(Data.leftArm)
	end

	if Data.rightArm then
		Colors.RightArmColor3 =
			ToColor3(Data.rightArm)
	end

	if Data.leftLeg then
		Colors.LeftLegColor3 =
			ToColor3(Data.leftLeg)
	end

	if Data.rightLeg then
		Colors.RightLegColor3 =
			ToColor3(Data.rightLeg)
	end
end

local function ApplyClothing(
	Character,
	Avatar
)
	for _, Object in ipairs(
		Character:GetChildren()
	) do
		if
			Object:IsA("Shirt")
			or Object:IsA("Pants")
			or Object:IsA("ShirtGraphic")
		then
			Object:Destroy()
		end
	end

	local Clothing =
		Avatar.clothing

	if type(Clothing) ~= "table" then
		return
	end

	if
		type(Clothing.shirt) == "table"
		and Clothing.shirt.texture
	then
		local Shirt =
			Instance.new("Shirt")

		Shirt.Name =
			Clothing.shirt.name
			or "Shirt"

		Shirt.ShirtTemplate =
			Clothing.shirt.texture

		Shirt.Parent =
			Character
	end

	if
		type(Clothing.pants) == "table"
		and Clothing.pants.texture
	then
		local Pants =
			Instance.new("Pants")

		Pants.Name =
			Clothing.pants.name
			or "Pants"

		Pants.PantsTemplate =
			Clothing.pants.texture

		Pants.Parent =
			Character
	end

	if
		type(Clothing.tshirt) == "table"
		and Clothing.tshirt.texture
	then
		local Graphic =
			Instance.new(
				"ShirtGraphic"
			)

		Graphic.Name =
			Clothing.tshirt.name
			or "ShirtGraphic"

		Graphic.Graphic =
			Clothing.tshirt.texture

		Graphic.Parent =
			Character
	end
end

local function ApplyHumanoid(
	Humanoid,
	Avatar
)
	local Data =
		Avatar.humanoid

	if type(Data) ~= "table" then
		return
	end

	if Data.walkSpeed ~= nil then
		Humanoid.WalkSpeed =
			Data.walkSpeed
	end

	if Data.jumpPower ~= nil then
		Humanoid.JumpPower =
			Data.jumpPower
	end

	if Data.jumpHeight ~= nil then
		Humanoid.JumpHeight =
			Data.jumpHeight
	end

	if Data.useJumpPower ~= nil then
		Humanoid.UseJumpPower =
			Data.useJumpPower
	end

	if Data.hipHeight ~= nil then
		Humanoid.HipHeight =
			Data.hipHeight
	end

	if Data.autoRotate ~= nil then
		Humanoid.AutoRotate =
			Data.autoRotate
	end

	if Data.displayName then
		pcall(function()
			Humanoid.DisplayName =
				Data.displayName
		end)
	end
end

local function ApplyAnimations(
	Character,
	Humanoid,
	Avatar
)
	if type(Avatar.animations) ~= "table" then
		return
	end

	local Animate =
		Character:FindFirstChild(
			"Animate"
		)

	if not Animate then
		return
	end

	for _, Saved in ipairs(
		Avatar.animations
	) do
		if
			Saved.parent
			and Saved.name
			and Saved.animationId
		then
			local Folder =
				Animate:FindFirstChild(
					Saved.parent
				)

			if Folder then
				local Animation =
					Folder:FindFirstChild(
						Saved.name
					)

				if
					Animation
					and Animation:IsA(
						"Animation"
					)
				then
					Animation.AnimationId =
						Saved.animationId
				end
			end
		end
	end

	local Animator =
		Humanoid:FindFirstChildOfClass(
			"Animator"
		)

	if Animator then
		for _, Track in ipairs(
			Animator:GetPlayingAnimationTracks()
		) do
			pcall(function()
				Track:Stop(0.05)
			end)
		end
	end
end

local Applying = false
local CurrentAvatarName

local function ApplyAvatar(AvatarName)
	if Applying then
		return false
	end

	Applying = true

	local Data =
		LoadData()

	if not Data then
		Applying = false
		return false
	end

	local Name =
		AvatarName

	if
		type(Name) ~= "string"
		or Name == ""
	then
		Name =
			Data.selected
	end

	local Avatar =
		GetAvatar(
			Data,
			Name
		)

	if not Avatar then
		Applying = false
		return false
	end

	local Character =
		Player.Character
		or Player.CharacterAdded:Wait()

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not Humanoid then
		Humanoid =
			Character:WaitForChild(
				"Humanoid",
				10
			)
	end

	if not Humanoid then
		Applying = false
		return false
	end

	CurrentAvatarName =
		Name

	local SavedBodyMap =
		BuildSavedBodyMap(
			Avatar
		)

	ApplyHumanoid(
		Humanoid,
		Avatar
	)

	ApplyBodyColors(
		Character,
		Avatar
	)

	ApplyBodyVisuals(
		Character,
		Humanoid,
		SavedBodyMap
	)

	ApplyClothing(
		Character,
		Avatar
	)

	ApplyAccessories(
		Character,
		Humanoid,
		Avatar,
		SavedBodyMap
	)

	ApplyAnimations(
		Character,
		Humanoid,
		Avatar
	)

	Applying = false

	return true
end

if Environment.CatalogServiceCharacterConnection then
	pcall(function()
		Environment.CatalogServiceCharacterConnection:Disconnect()
	end)
end

Environment.CatalogServiceCharacterConnection =
	Player.CharacterAdded:Connect(
		function(Character)
			Character:WaitForChild(
				"Humanoid"
			)

			task.wait(0.75)

			if CurrentAvatarName then
				ApplyAvatar(
					CurrentAvatarName
				)
			end
		end
	)

return ApplyAvatar
