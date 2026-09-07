local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

local Base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(Data)
	return (
	(Data:gsub(".", function(Character)
		local Byte = Character:byte()
		local Bits = ""

		for Index = 8, 1, -1 do
			Bits = Bits
			.. (
			Byte % 2 ^ Index
			- Byte % 2 ^ (Index - 1)
			> 0
			and "1"
			or "0"
			)
		end

		return Bits
	end) .. "0000")
	:gsub("%d%d%d?%d?%d?%d?", function(Bits)
		if #Bits < 6 then
			return ""
		end

		local Value = 0

		for Index = 1, 6 do
			if Bits:sub(Index, Index) == "1" then
				Value =
					Value
					+ 2 ^ (6 - Index)
			end
		end

		return Base64Chars:sub(
			Value + 1,
			Value + 1
		)
	end)
	.. ({
		"",
		"==",
		"="
	})[#Data % 3 + 1]
	)
end

local function AssetId(Value)
	if not Value then
		return 0
	end

	if type(Value) == "number" then
		return Value
	end

	return tonumber(
		tostring(Value):match("%d+")
	) or 0
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

local function AddCatalogItem(List, ID)
	ID = AssetId(ID)

	if ID <= 0 then
		return
	end

	table.insert(List, {
		type = "catalog",
		data = Base64Encode(
			tostring(ID)
		)
	})
end

local function ParseAccessoryList(List, Value)
	if not Value or Value == "" then
		return 0
	end

	local Count = 0

	for ID in tostring(Value):gmatch("%d+") do
		AddCatalogItem(
			List,
			tonumber(ID)
		)

		Count = Count + 1
	end

	return Count
end

local function GetDescriptionValue(Description, Property)
	local Success, Value = pcall(function()
		return Description[Property]
	end)

	if Success then
		return Value
	end

	return nil
end

local function ExtractRawAccessory(Accessory)
	local Handle =
		Accessory:FindFirstChild("Handle")

	if not Handle or not Handle:IsA("BasePart") then
		return nil
	end

	local MeshId
	local TextureId

	if Handle:IsA("MeshPart") then
		MeshId = Handle.MeshId
		TextureId = Handle.TextureID
	else
		local Mesh =
			Handle:FindFirstChildOfClass("SpecialMesh")

		if Mesh then
			MeshId = Mesh.MeshId
			TextureId = Mesh.TextureId
		end
	end

	if not MeshId or MeshId == "" then
		return nil
	end

	local Data = {
		name = Accessory.Name,
		meshId = MeshId,
		textureId = TextureId or "",
		size = VectorToTable(Handle.Size)
	}

	local Attachment =
		Handle:FindFirstChildOfClass("Attachment")

	if Attachment then
		Data.attachment = Attachment.Name
		Data.attachmentCFrame =
			CFrameToTable(Attachment.CFrame)
	end

	local Weld =
		Handle:FindFirstChild("AccessoryWeld")

	if Weld and Weld:IsA("Weld") then
		Data.handleCFrame =
			CFrameToTable(Weld.C0)

		Data.targetCFrame =
			CFrameToTable(Weld.C1)

		if Weld.Part1 then
			Data.targetPart =
				Weld.Part1.Name
		end
	end

	return {
		type = "raw",

		data = Base64Encode(
			HttpService:JSONEncode(Data)
		)
	}
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

local Output = {
	selected = "Extracted",

	avatars = {
		Extracted = {
			items = {},

			body = {},
			clothing = {},
			animations = {},
			scales = {}
		}
	}
}

local Avatar =
	Output.avatars.Extracted

local AccessoryProperties = {
	"HatAccessory",
	"HairAccessory",
	"FaceAccessory",
	"NeckAccessory",
	"ShouldersAccessory",
	"FrontAccessory",
	"BackAccessory",
	"WaistAccessory",

	"TShirtAccessory",
	"ShirtAccessory",
	"PantsAccessory",
	"JacketAccessory",
	"SweaterAccessory",
	"ShortsAccessory",
	"LeftShoeAccessory",
	"RightShoeAccessory",
	"DressSkirtAccessory"
}

local AccessoryIdCount = 0

for _, Property in ipairs(AccessoryProperties) do
	local Value =
		GetDescriptionValue(
			Description,
			Property
		)

	AccessoryIdCount =
		AccessoryIdCount
		+ ParseAccessoryList(
			Avatar.items,
			Value
		)
end

local BodyProperties = {
	"Head",
	"Torso",
	"LeftArm",
	"RightArm",
	"LeftLeg",
	"RightLeg"
}

for _, Property in ipairs(BodyProperties) do
	local Value =
		AssetId(
			GetDescriptionValue(
				Description,
				Property
			)
		)

	if Value > 0 then
		Avatar.body[Property] = Value
	end
end

local ClothingProperties = {
	"Shirt",
	"Pants",
	"GraphicTShirt",
	"Face"
}

for _, Property in ipairs(ClothingProperties) do
	local Value =
		AssetId(
			GetDescriptionValue(
				Description,
				Property
			)
		)

	if Value > 0 then
		Avatar.clothing[Property] = Value
	end
end

local AnimationProperties = {
	"ClimbAnimation",
	"FallAnimation",
	"IdleAnimation",
	"JumpAnimation",
	"RunAnimation",
	"SwimAnimation",
	"WalkAnimation"
}

for _, Property in ipairs(AnimationProperties) do
	local Value =
		AssetId(
			GetDescriptionValue(
				Description,
				Property
			)
		)

	if Value > 0 then
		Avatar.animations[Property] = Value
	end
end

local ScaleProperties = {
	"HeightScale",
	"WidthScale",
	"DepthScale",
	"HeadScale",
	"BodyTypeScale",
	"ProportionScale"
}

for _, Property in ipairs(ScaleProperties) do
	local Value =
		GetDescriptionValue(
			Description,
			Property
		)

	if type(Value) == "number" then
		Avatar.scales[Property] =
			Value
	end
end

if AccessoryIdCount == 0 then
	for _, Object in ipairs(Character:GetChildren()) do
		if Object:IsA("Accessory") then
			local Raw =
				ExtractRawAccessory(
					Object
				)

			if Raw then
				table.insert(
					Avatar.items,
					Raw
				)
			end
		end
	end
end

local Animate =
	Character:FindFirstChild("Animate")

if Animate then
	Avatar.runtimeAnimations = {}

	for _, Object in ipairs(Animate:GetDescendants()) do
		if Object:IsA("Animation") then
			local ID =
				AssetId(
					Object.AnimationId
				)

			if ID > 0 then
				local Key = Object.Name

				if
				Avatar.runtimeAnimations[Key]
				~= nil
				and Object.Parent
				then
					Key =
						Object.Parent.Name
						.. "_"
						.. Object.Name
				end

				Avatar.runtimeAnimations[Key] =
					ID
			end
		end
	end
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "AvatarExtractor"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true

pcall(function()
	Gui.Parent = CoreGui
end)

if not Gui.Parent then
	Gui.Parent =
		Player:WaitForChild("PlayerGui")
end

local TextBox = Instance.new("TextBox")
TextBox.Name = "Output"
TextBox.AnchorPoint =
	Vector2.new(0.5, 0.5)

TextBox.Position =
	UDim2.fromScale(0.5, 0.5)

TextBox.Size =
	UDim2.fromOffset(700, 400)

TextBox.BackgroundColor3 =
	Color3.fromRGB(20, 20, 20)

TextBox.TextColor3 =
	Color3.fromRGB(235, 235, 235)

TextBox.PlaceholderColor3 =
	Color3.fromRGB(130, 130, 130)

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

TextBox.Text =
	HttpService:JSONEncode(Output)

TextBox.Parent = Gui

local Corner =
	Instance.new("UICorner")

Corner.CornerRadius =
	UDim.new(0, 8)

Corner.Parent =
	TextBox

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

Padding.Parent =
	TextBox

TextBox:CaptureFocus()
TextBox.CursorPosition =
	#TextBox.Text + 1