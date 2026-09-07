local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

local Base64Chars =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(Data)
	return ((Data:gsub(".", function(Character)
		local Byte = Character:byte()
		local Bits = ""

		for Index = 8, 1, -1 do
			Bits ..=
			Byte % 2 ^ Index - Byte % 2 ^ (Index - 1) > 0
			and "1"
			or "0"
		end

		return Bits
	end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(Bits)
		if #Bits < 6 then
			return ""
		end

		local Value = 0

		for Index = 1, 6 do
			if Bits:sub(Index, Index) == "1" then
				Value += 2 ^ (6 - Index)
			end
		end

		return Base64Chars:sub(
			Value + 1,
			Value + 1
		)
	end) .. ({
		"",
		"==",
		"="
	})[#Data % 3 + 1])
end

local function CFrameToTable(Value)
	return {
		Value:GetComponents()
	}
end

local function VectorToTable(Value)
	return {
		Value.X,
		Value.Y,
		Value.Z
	}
end

local function ColorToTable(Value)
	return {
		Value.R,
		Value.G,
		Value.B
	}
end

local function EncodeData(Data)
	return Base64Encode(
		HttpService:JSONEncode(Data)
	)
end

local function GetProperty(Object, Property)
	local Success, Value = pcall(function()
		return Object[Property]
	end)

	if Success then
		return Value
	end

	return nil
end

local function GetPossibleAssetId(Object)
	local Properties = {
		"SourceAssetId",
		"AssetId"
	}

	for _, Property in ipairs(Properties) do
		local Value = GetProperty(
			Object,
			Property
		)

		if type(Value) == "number" and Value > 0 then
			return Value
		end
	end

	return nil
end

local function ExtractAttachment(Attachment)
	return {
		name = Attachment.Name,
		cframe = CFrameToTable(
			Attachment.CFrame
		),
		position = VectorToTable(
			Attachment.Position
		),
		orientation = VectorToTable(
			Attachment.Orientation
		)
	}
end

local function ExtractAttachments(Object)
	local Result = {}

	for _, Child in ipairs(Object:GetChildren()) do
		if Child:IsA("Attachment") then
			table.insert(
				Result,
				ExtractAttachment(Child)
			)
		end
	end

	return Result
end

local function ExtractMesh(BasePart)
	local Data = {}

	if BasePart:IsA("MeshPart") then
		Data.meshType = "MeshPart"
		Data.meshId = BasePart.MeshId
		Data.textureId = BasePart.TextureID

		local RenderFidelity = GetProperty(
			BasePart,
			"RenderFidelity"
		)

		if RenderFidelity then
			Data.renderFidelity =
				RenderFidelity.Name
		end

		local DoubleSided = GetProperty(
			BasePart,
			"DoubleSided"
		)

		if DoubleSided ~= nil then
			Data.doubleSided = DoubleSided
		end

		return Data
	end

	local SpecialMesh =
		BasePart:FindFirstChildOfClass("SpecialMesh")

	if SpecialMesh then
		Data.meshType = "SpecialMesh"
		Data.meshId = SpecialMesh.MeshId
		Data.textureId = SpecialMesh.TextureId
		Data.scale = VectorToTable(
			SpecialMesh.Scale
		)
		Data.offset = VectorToTable(
			SpecialMesh.Offset
		)
		Data.vertexColor = VectorToTable(
			SpecialMesh.VertexColor
		)
		Data.meshEnum = SpecialMesh.MeshType.Name

		return Data
	end

	Data.meshType = "Part"

	return Data
end

local function ExtractWeld(Weld)
	local Data = {
		name = Weld.Name
	}

	if Weld.Part0 then
		Data.part0 = Weld.Part0.Name
	end

	if Weld.Part1 then
		Data.part1 = Weld.Part1.Name
	end

	if Weld:IsA("Weld") then
		Data.c0 = CFrameToTable(Weld.C0)
		Data.c1 = CFrameToTable(Weld.C1)

	elseif Weld:IsA("Motor6D") then
		Data.c0 = CFrameToTable(Weld.C0)
		Data.c1 = CFrameToTable(Weld.C1)
		Data.transform =
			CFrameToTable(Weld.Transform)

	elseif Weld:IsA("WeldConstraint") then
		Data.weldConstraint = true
	end

	return Data
end

local function ExtractAccessory(Accessory)
	local Data = {
		name = Accessory.Name,
		className = Accessory.ClassName,
		accessoryType = Accessory.AccessoryType.Name
	}

	local PossibleId =
		GetPossibleAssetId(Accessory)

	if PossibleId then
		Data.avatarItemId = PossibleId
	end

	local Handle =
		Accessory:FindFirstChild("Handle")

	if not Handle or not Handle:IsA("BasePart") then
		return Data
	end

	local HandleId =
		GetPossibleAssetId(Handle)

	if not Data.avatarItemId and HandleId then
		Data.avatarItemId = HandleId
	end

	Data.handle = {
		className = Handle.ClassName,

		size = VectorToTable(
			Handle.Size
		),

		cframe = CFrameToTable(
			Handle.CFrame
		),

		color = ColorToTable(
			Handle.Color
		),

		transparency =
		Handle.Transparency,

		reflectance =
		Handle.Reflectance,

		material =
		Handle.Material.Name,

		canCollide =
		Handle.CanCollide,

		canTouch =
		Handle.CanTouch,

		canQuery =
		Handle.CanQuery,

		massless =
		Handle.Massless,

		mesh =
		ExtractMesh(Handle),

		attachments =
		ExtractAttachments(Handle),

		welds = {}
	}

	for _, Child in ipairs(Handle:GetChildren()) do
		if
		Child:IsA("Weld")
		or Child:IsA("Motor6D")
		or Child:IsA("WeldConstraint")
		then
			table.insert(
				Data.handle.welds,
				ExtractWeld(Child)
			)
		end
	end

	return Data
end

local function ExtractBodyPart(Part)
	local Data = {
		name = Part.Name,
		className = Part.ClassName,

		size = VectorToTable(
			Part.Size
		),

		cframe = CFrameToTable(
			Part.CFrame
		),

		color = ColorToTable(
			Part.Color
		),

		transparency =
		Part.Transparency,

		material =
		Part.Material.Name,

		reflectance =
		Part.Reflectance,

		mesh =
		ExtractMesh(Part),

		attachments =
		ExtractAttachments(Part),

		joints = {}
	}

	local PossibleId =
		GetPossibleAssetId(Part)

	if PossibleId then
		Data.avatarItemId = PossibleId
	end

	for _, Child in ipairs(Part:GetChildren()) do
		if
		Child:IsA("Motor6D")
		or Child:IsA("Weld")
		or Child:IsA("WeldConstraint")
		then
			table.insert(
				Data.joints,
				ExtractWeld(Child)
			)
		end
	end

	return Data
end

local function ExtractAnimations(Character)
	local Result = {}

	for _, Object in ipairs(Character:GetDescendants()) do
		if Object:IsA("Animation") then
			table.insert(Result, {
				name = Object.Name,

				parent =
				Object.Parent
				and Object.Parent.Name
				or "",

				animationId =
				Object.AnimationId
			})
		end
	end

	return Result
end

local function ExtractPlayingAnimations(Humanoid)
	local Result = {}

	local Animator =
		Humanoid:FindFirstChildOfClass("Animator")

	if not Animator then
		return Result
	end

	for _, Track in ipairs(
		Animator:GetPlayingAnimationTracks()
	) do
		local Animation = Track.Animation

		table.insert(Result, {
			animationId =
			Animation
			and Animation.AnimationId
			or "",

			name = Track.Name,

			priority =
			Track.Priority.Name,

			speed = Track.Speed,

			timePosition =
			Track.TimePosition,

			weight =
			Track.WeightCurrent,

			looped =
			Track.Looped
		})
	end

	return Result
end

local function ExtractClothing(Character)
	local Result = {}

	for _, Object in ipairs(Character:GetChildren()) do
		if Object:IsA("Shirt") then
			Result.shirt = {
				name = Object.Name,
				texture = Object.ShirtTemplate
			}

		elseif Object:IsA("Pants") then
			Result.pants = {
				name = Object.Name,
				texture = Object.PantsTemplate
			}

		elseif Object:IsA("ShirtGraphic") then
			Result.tshirt = {
				name = Object.Name,
				texture = Object.Graphic
			}
		end
	end

	return Result
end

local function ExtractDecals(Character)
	local Result = {}

	for _, Object in ipairs(Character:GetDescendants()) do
		if Object:IsA("Decal") then
			table.insert(Result, {
				name = Object.Name,

				parent =
				Object.Parent
				and Object.Parent.Name
				or "",

				texture =
				Object.Texture,

				face =
				Object.Face.Name,

				transparency =
				Object.Transparency,

				color =
				ColorToTable(
					Object.Color3
				)
			})
		end
	end

	return Result
end

local function ExtractBodyColors(Character)
	local BodyColors =
		Character:FindFirstChildOfClass(
			"BodyColors"
		)

	if not BodyColors then
		return nil
	end

	return {
		head =
		ColorToTable(
			BodyColors.HeadColor3
		),

		leftArm =
		ColorToTable(
			BodyColors.LeftArmColor3
		),

		rightArm =
		ColorToTable(
			BodyColors.RightArmColor3
		),

		leftLeg =
		ColorToTable(
			BodyColors.LeftLegColor3
		),

		rightLeg =
		ColorToTable(
			BodyColors.RightLegColor3
		),

		torso =
		ColorToTable(
			BodyColors.TorsoColor3
		)
	}
end

local function ExtractHumanoid(Humanoid)
	return {
		rigType =
		Humanoid.RigType.Name,

		walkSpeed =
		Humanoid.WalkSpeed,

		jumpPower =
		Humanoid.JumpPower,

		jumpHeight =
		Humanoid.JumpHeight,

		useJumpPower =
		Humanoid.UseJumpPower,

		hipHeight =
		Humanoid.HipHeight,

		autoRotate =
		Humanoid.AutoRotate,

		maxHealth =
		Humanoid.MaxHealth,

		health =
		Humanoid.Health,

		nameDisplayDistance =
		Humanoid.NameDisplayDistance,

		healthDisplayDistance =
		Humanoid.HealthDisplayDistance,

		displayName =
		Humanoid.DisplayName
	}
end

local function ExtractCharacter()
	local Character = Player.Character

	if not Character then
		return "{}"
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not Humanoid then
		return "{}"
	end

	local Avatar = {
		version = 2,
		source = "character",
		name = Character.Name,

		accessories = {},
		bodyParts = {},

		clothing =
		ExtractClothing(Character),

		decals =
		ExtractDecals(Character),

		animations =
		ExtractAnimations(Character),

		playingAnimations =
		ExtractPlayingAnimations(
			Humanoid
		),

		bodyColors =
		ExtractBodyColors(Character),

		humanoid =
		ExtractHumanoid(Humanoid)
	}

	for _, Object in ipairs(
		Character:GetChildren()
	) do
		if Object:IsA("Accessory") then
			local Data =
				ExtractAccessory(Object)

			table.insert(
				Avatar.accessories,
				{
					type = "actualAccessory",
					data = EncodeData(Data)
				}
			)

		elseif Object:IsA("BasePart") then
			local Data =
				ExtractBodyPart(Object)

			table.insert(
				Avatar.bodyParts,
				{
					type = "actualBodyPart",
					data = EncodeData(Data)
				}
			)
		end
	end

	return HttpService:JSONEncode({
		selected = "Extracted",

		avatars = {
			Extracted = Avatar
		}
	})
end

local PlayerGui =
	Player:WaitForChild("PlayerGui")

local OldGui =
	CoreGui:FindFirstChild(
		"AvatarExtractor"
	)
	or PlayerGui:FindFirstChild(
		"AvatarExtractor"
	)

if OldGui then
	OldGui:Destroy()
end

local Gui =
	Instance.new("ScreenGui")

Gui.Name = "AvatarExtractor"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true

pcall(function()
	Gui.Parent = CoreGui
end)

if not Gui.Parent then
	Gui.Parent = PlayerGui
end

local Container =
	Instance.new("Frame")

Container.Name = "Container"
Container.AnchorPoint =
	Vector2.new(0.5, 0.5)

Container.Position =
	UDim2.fromScale(0.5, 0.5)

Container.Size =
	UDim2.fromOffset(
		720,
		470
	)

Container.BackgroundTransparency = 1
Container.Parent = Gui

local TextBox =
	Instance.new("TextBox")

TextBox.Name = "Output"

TextBox.Position =
	UDim2.fromOffset(
		0,
		0
	)

TextBox.Size =
	UDim2.new(
		1,
		0,
		1,
		-50
	)

TextBox.BackgroundColor3 =
	Color3.fromRGB(
		20,
		20,
		20
	)

TextBox.TextColor3 =
	Color3.fromRGB(
		235,
		235,
		235
	)

TextBox.BorderSizePixel = 0
TextBox.ClearTextOnFocus = false
TextBox.MultiLine = true
TextBox.TextWrapped = false

TextBox.TextXAlignment =
	Enum.TextXAlignment.Left

TextBox.TextYAlignment =
	Enum.TextYAlignment.Top

TextBox.Font =
	Enum.Font.Code

TextBox.TextSize = 15

TextBox.Parent = Container

local Corner =
	Instance.new("UICorner")

Corner.CornerRadius =
	UDim.new(0, 8)

Corner.Parent = TextBox

local Padding =
	Instance.new("UIPadding")

Padding.PaddingTop =
	UDim.new(0, 12)

Padding.PaddingBottom =
	UDim.new(0, 12)

Padding.PaddingLeft =
	UDim.new(0, 12)

Padding.PaddingRight =
	UDim.new(0, 12)

Padding.Parent = TextBox

local Refresh =
	Instance.new("TextButton")

Refresh.Name = "Refresh"

Refresh.AnchorPoint =
	Vector2.new(0.5, 1)

Refresh.Position =
	UDim2.new(
		0.5,
		0,
		1,
		0
	)

Refresh.Size =
	UDim2.fromOffset(
		140,
		38
	)

Refresh.BackgroundColor3 =
	Color3.fromRGB(
		35,
		35,
		35
	)

Refresh.TextColor3 =
	Color3.fromRGB(
		235,
		235,
		235
	)

Refresh.BorderSizePixel = 0
Refresh.Font = Enum.Font.GothamMedium
Refresh.TextSize = 14
Refresh.Text = "Refresh"

Refresh.Parent = Container

local RefreshCorner =
	Instance.new("UICorner")

RefreshCorner.CornerRadius =
	UDim.new(0, 8)

RefreshCorner.Parent =
	Refresh

local function RefreshAvatar()
	TextBox.Text =
		ExtractCharacter()

	TextBox.CursorPosition =
		#TextBox.Text + 1
end

Refresh.MouseButton1Click:Connect(
	function()
		RefreshAvatar()
	end
)

Player.CharacterAdded:Connect(
	function(Character)
		Character:WaitForChild(
			"Humanoid"
		)

		task.wait()

		RefreshAvatar()
	end
)

RefreshAvatar()
