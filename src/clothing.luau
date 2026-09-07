local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local JSON_URLS = {
	"https://raw.githubusercontent.com/cwcodemaker1/Catalog-Service/main/avatars.json",
	"https://raw.githubusercontent.com/cwcodemaker1/Catalog-Service/main/src/avatars.json"
}

local Base64Characters =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Decode(Data)
	Data = Data:gsub("[^" .. Base64Characters .. "=]", "")

	return (
		Data:gsub(".", function(Character)
			if Character == "=" then
				return ""
			end

			local Position =
				Base64Characters:find(
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

local function Vector3FromTable(Data)
	if type(Data) ~= "table" then
		return Vector3.zero
	end

	return Vector3.new(
		tonumber(Data[1]) or 0,
		tonumber(Data[2]) or 0,
		tonumber(Data[3]) or 0
	)
end

local function Color3FromTable(Data)
	if type(Data) ~= "table" then
		return Color3.new(1, 1, 1)
	end

	return Color3.new(
		tonumber(Data[1]) or 1,
		tonumber(Data[2]) or 1,
		tonumber(Data[3]) or 1
	)
end

local function CFrameFromTable(Data)
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

local function DecodeObject(Data)
	if type(Data) ~= "string" then
		return nil
	end

	local Success, Result = pcall(function()
		return HttpService:JSONDecode(
			Base64Decode(Data)
		)
	end)

	if Success then
		return Result
	end

	return nil
end

local function LoadJSON()
	if type(readfile) == "function" then
		local Paths = {
			"avatars.json",
			"Catalog-Service/avatars.json",
			"Catalog-Service/src/avatars.json"
		}

		for _, Path in ipairs(Paths) do
			local CanRead = true

			if type(isfile) == "function" then
				CanRead = isfile(Path)
			end

			if CanRead then
				local Success, Result = pcall(function()
					return HttpService:JSONDecode(
						readfile(Path)
					)
				end)

				if Success and type(Result) == "table" then
					return Result
				end
			end
		end
	end

	for _, URL in ipairs(JSON_URLS) do
		local Success, Result = pcall(function()
			local Source = game:HttpGet(
				URL
					.. "?t="
					.. tostring(os.time())
			)

			return HttpService:JSONDecode(Source)
		end)

		if Success and type(Result) == "table" then
			return Result
		end
	end

	return nil
end

local function GetSelectedAvatar()
	local JSON = LoadJSON()

	if not JSON then
		return nil
	end

	local Name = JSON.selected

	if
		not Name
		or type(JSON.avatars) ~= "table"
		or type(JSON.avatars[Name]) ~= "table"
	then
		return nil
	end

	return JSON.avatars[Name]
end

local function CreateMeshPart(MeshData)
	if
		type(MeshData) ~= "table"
		or not MeshData.meshId
		or MeshData.meshId == ""
	then
		return nil
	end

	local Success, Part = pcall(function()
		return InsertService:CreateMeshPartAsync(
			MeshData.meshId,
			Enum.CollisionFidelity.Default,
			Enum.RenderFidelity.Automatic
		)
	end)

	if Success and Part then
		if MeshData.textureId then
			pcall(function()
				Part.TextureID =
					MeshData.textureId
			end)
		end

		if MeshData.doubleSided ~= nil then
			pcall(function()
				Part.DoubleSided =
					MeshData.doubleSided
			end)
		end

		return Part
	end

	return nil
end

local function ApplyAttachments(Part, Attachments)
	if type(Attachments) ~= "table" then
		return
	end

	for _, Data in ipairs(Attachments) do
		if Data.name then
			local Attachment =
				Part:FindFirstChild(Data.name)

			if
				not Attachment
				or not Attachment:IsA("Attachment")
			then
				if Attachment then
					Attachment:Destroy()
				end

				Attachment =
					Instance.new("Attachment")

				Attachment.Name = Data.name
				Attachment.Parent = Part
			end

			if Data.cframe then
				Attachment.CFrame =
					CFrameFromTable(
						Data.cframe
					)
			elseif Data.position then
				Attachment.Position =
					Vector3FromTable(
						Data.position
					)

				if Data.orientation then
					Attachment.Orientation =
						Vector3FromTable(
							Data.orientation
						)
				end
			end
		end
	end
end

local function FindCharacterAttachment(
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
			and not Object:IsDescendantOf(Ignore)
		then
			return Object
		end
	end

	return nil
end

local function ManualAccessoryWeld(
	Character,
	Accessory,
	Handle
)
	local HandleAttachment =
		Handle:FindFirstChildOfClass(
			"Attachment"
		)

	if not HandleAttachment then
		return
	end

	local Target =
		FindCharacterAttachment(
			Character,
			HandleAttachment.Name,
			Accessory
		)

	if
		not Target
		or not Target.Parent
		or not Target.Parent:IsA("BasePart")
	then
		return
	end

	local Existing =
		Handle:FindFirstChild(
			"AccessoryWeld"
		)

	if Existing then
		Existing:Destroy()
	end

	local Weld = Instance.new("Weld")
	Weld.Name = "AccessoryWeld"

	Weld.Part0 = Handle
	Weld.Part1 = Target.Parent

	Weld.C0 =
		HandleAttachment.CFrame

	Weld.C1 =
		Target.CFrame

	Weld.Parent = Handle
end

local function CreateAccessory(
	Character,
	Humanoid,
	Data
)
	if
		type(Data) ~= "table"
		or type(Data.handle) ~= "table"
	then
		return
	end

	local Accessory =
		Instance.new("Accessory")

	Accessory.Name =
		Data.name
		or "StoredAccessory"

	if Data.accessoryType then
		pcall(function()
			Accessory.AccessoryType =
				Enum.AccessoryType[
					Data.accessoryType
				]
		end)
	end

	local HandleData = Data.handle
	local Handle

	if
		type(HandleData.mesh) == "table"
		and HandleData.mesh.meshId
		and HandleData.mesh.meshId ~= ""
	then
		Handle =
			CreateMeshPart(
				HandleData.mesh
			)
	end

	if not Handle then
		Handle = Instance.new("Part")

		if
			type(HandleData.mesh) == "table"
			and HandleData.mesh.meshId
		then
			local Mesh =
				Instance.new("SpecialMesh")

			Mesh.MeshType =
				Enum.MeshType.FileMesh

			Mesh.MeshId =
				HandleData.mesh.meshId

			Mesh.TextureId =
				HandleData.mesh.textureId
				or ""

			if HandleData.mesh.scale then
				Mesh.Scale =
					Vector3FromTable(
						HandleData.mesh.scale
					)
			end

			if HandleData.mesh.offset then
				Mesh.Offset =
					Vector3FromTable(
						HandleData.mesh.offset
					)
			end

			Mesh.Parent = Handle
		end
	end

	Handle.Name = "Handle"

	if HandleData.size then
		Handle.Size =
			Vector3FromTable(
				HandleData.size
			)
	end

	if HandleData.color then
		Handle.Color =
			Color3FromTable(
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

	Handle.CanCollide = false
	Handle.CanTouch = false
	Handle.CanQuery = false
	Handle.Massless = true

	ApplyAttachments(
		Handle,
		HandleData.attachments
	)

	Handle.Parent = Accessory

	local Success =
		pcall(function()
			Humanoid:AddAccessory(
				Accessory
			)
		end)

	if not Success then
		Accessory.Parent = Character
	end

	if not Accessory.Parent then
		Accessory.Parent = Character
	end

	RunService.Heartbeat:Wait()

	if
		not Handle:FindFirstChild(
			"AccessoryWeld"
		)
	then
		ManualAccessoryWeld(
			Character,
			Accessory,
			Handle
		)
	end
end

local function ApplyAccessories(
	Character,
	Humanoid,
	Avatar
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

	for _, Entry in ipairs(
		Avatar.accessories
	) do
		if
			Entry.type == "actualAccessory"
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
					Data
				)
			end
		end
	end
end

local function ApplyClassicClothing(
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

	local Clothing = Avatar.clothing

	if type(Clothing) ~= "table" then
		return
	end

	if
		type(Clothing.shirt) == "table"
		and Clothing.shirt.texture
	then
		local Shirt = Instance.new("Shirt")

		Shirt.Name =
			Clothing.shirt.name
			or "Shirt"

		Shirt.ShirtTemplate =
			Clothing.shirt.texture

		Shirt.Parent = Character
	end

	if
		type(Clothing.pants) == "table"
		and Clothing.pants.texture
	then
		local Pants = Instance.new("Pants")

		Pants.Name =
			Clothing.pants.name
			or "Pants"

		Pants.PantsTemplate =
			Clothing.pants.texture

		Pants.Parent = Character
	end

	if
		type(Clothing.tshirt) == "table"
		and Clothing.tshirt.texture
	then
		local Graphic =
			Instance.new("ShirtGraphic")

		Graphic.Name =
			Clothing.tshirt.name
			or "Shirt Graphic"

		Graphic.Graphic =
			Clothing.tshirt.texture

		Graphic.Parent = Character
	end
end

local function ApplyBodyColors(
	Character,
	Avatar
)
	local Data = Avatar.bodyColors

	if type(Data) ~= "table" then
		return
	end

	local BodyColors =
		Character:FindFirstChildOfClass(
			"BodyColors"
		)

	if not BodyColors then
		BodyColors =
			Instance.new("BodyColors")

		BodyColors.Parent = Character
	end

	if Data.head then
		BodyColors.HeadColor3 =
			Color3FromTable(Data.head)
	end

	if Data.torso then
		BodyColors.TorsoColor3 =
			Color3FromTable(Data.torso)
	end

	if Data.leftArm then
		BodyColors.LeftArmColor3 =
			Color3FromTable(Data.leftArm)
	end

	if Data.rightArm then
		BodyColors.RightArmColor3 =
			Color3FromTable(Data.rightArm)
	end

	if Data.leftLeg then
		BodyColors.LeftLegColor3 =
			Color3FromTable(Data.leftLeg)
	end

	if Data.rightLeg then
		BodyColors.RightLegColor3 =
			Color3FromTable(Data.rightLeg)
	end
end

local function ApplyBodyPart(
	Character,
	Data
)
	if
		type(Data) ~= "table"
		or not Data.name
	then
		return
	end

	local Part =
		Character:FindFirstChild(
			Data.name
		)

	if
		not Part
		or not Part:IsA("BasePart")
	then
		return
	end

	if Data.name ~= "HumanoidRootPart" then
		if Data.size then
			Part.Size =
				Vector3FromTable(
					Data.size
				)
		end

		if Data.color then
			Part.Color =
				Color3FromTable(
					Data.color
				)
		end

		if Data.transparency ~= nil then
			Part.Transparency =
				Data.transparency
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

		if
			Part:IsA("MeshPart")
			and type(Data.mesh) == "table"
			and Data.mesh.meshId
			and Data.mesh.meshId ~= ""
		then
			local Source =
				CreateMeshPart(
					Data.mesh
				)

			if Source then
				pcall(function()
					Part:ApplyMesh(Source)
				end)

				Source:Destroy()

				if Data.size then
					Part.Size =
						Vector3FromTable(
							Data.size
						)
				end
			end
		end
	end

	ApplyAttachments(
		Part,
		Data.attachments
	)

	-- Intentionally NOT applying Data.cframe.
	-- That is the old WORLD position from extraction.
end

local function ApplyBodyParts(
	Character,
	Avatar
)
	if type(Avatar.bodyParts) ~= "table" then
		return
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if Humanoid then
		pcall(function()
			Humanoid.AutomaticScalingEnabled =
				false
		end)
	end

	for _, Entry in ipairs(
		Avatar.bodyParts
	) do
		if
			Entry.type == "actualBodyPart"
			and Entry.data
		then
			local Data =
				DecodeObject(
					Entry.data
				)

			if Data then
				ApplyBodyPart(
					Character,
					Data
				)
			end
		end
	end
end

local function ApplyHumanoid(
	Humanoid,
	Avatar
)
	local Data = Avatar.humanoid

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
		if Saved.animationId then
			for _, Animation in ipairs(
				Animate:GetDescendants()
			) do
				if
					Animation:IsA("Animation")
					and Animation.Name == Saved.name
					and Animation.Parent
					and Animation.Parent.Name
						== Saved.parent
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
				Track:Stop(0)
			end)
		end
	end
end

local function ApplyDecals(
	Character,
	Avatar
)
	if type(Avatar.decals) ~= "table" then
		return
	end

	for _, Object in ipairs(
		Character:GetDescendants()
	) do
		if Object:IsA("Decal") then
			Object:Destroy()
		end
	end

	for _, Data in ipairs(
		Avatar.decals
	) do
		local Parent =
			Character:FindFirstChild(
				Data.parent,
				true
			)

		if Parent then
			local Decal =
				Instance.new("Decal")

			Decal.Name =
				Data.name
				or "face"

			Decal.Texture =
				Data.texture
				or ""

			if Data.transparency ~= nil then
				Decal.Transparency =
					Data.transparency
			end

			if Data.color then
				Decal.Color3 =
					Color3FromTable(
						Data.color
					)
			end

			if Data.face then
				pcall(function()
					Decal.Face =
						Enum.NormalId[
							Data.face
						]
				end)
			end

			Decal.Parent = Parent
		end
	end
end

local Applying = false

local function ApplyAvatar()
	if Applying then
		return
	end

	Applying = true

	local Avatar =
		GetSelectedAvatar()

	local Character =
		Player.Character

	if not Avatar or not Character then
		Applying = false
		return
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not Humanoid then
		Applying = false
		return
	end

	ApplyHumanoid(
		Humanoid,
		Avatar
	)

	ApplyBodyParts(
		Character,
		Avatar
	)

	ApplyBodyColors(
		Character,
		Avatar
	)

	ApplyClassicClothing(
		Character,
		Avatar
	)

	ApplyDecals(
		Character,
		Avatar
	)

	ApplyAccessories(
		Character,
		Humanoid,
		Avatar
	)

	ApplyAnimations(
		Character,
		Humanoid,
		Avatar
	)

	Applying = false
end

local Character =
	Player.Character
	or Player.CharacterAdded:Wait()

Character:WaitForChild("Humanoid")

task.wait(1)

ApplyAvatar()

Player.CharacterAdded:Connect(function(NewCharacter)
	NewCharacter:WaitForChild("Humanoid")

	task.wait(1)

	ApplyAvatar()
end)
