local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("AssetService")

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

			local Value =
				Position - 1

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
						Value +=
							2 ^ (8 - Index)
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

local function ToVector3(
	Data,
	Default
)
	Default =
		Default
		or Vector3.zero

	if type(Data) ~= "table" then
		return Default
	end

	return Vector3.new(
		tonumber(Data[1])
			or Default.X,

		tonumber(Data[2])
			or Default.Y,

		tonumber(Data[3])
			or Default.Z
	)
end

local function ToColor3(Data)
	if type(Data) ~= "table" then
		return Color3.new(
			1,
			1,
			1
		)
	end

	return Color3.new(
		tonumber(Data[1])
			or 1,

		tonumber(Data[2])
			or 1,

		tonumber(Data[3])
			or 1
	)
end

local function ToCFrame(Data)
	if
		type(Data) ~= "table"
		or #Data < 12
	then
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

local function GetAssetId(Value)
	if type(Value) == "number" then
		return Value
	end

	if type(Value) ~= "string" then
		return nil
	end

	return tonumber(
		Value:match("%d+")
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
				Exists =
					isfile(Path)
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
					and type(Result)
						== "table"
					and type(
						Result.avatars
					) == "table"
				then
					return Result
				end
			end
		end
	end

	for _, URL in ipairs(
		JSON_URLS
	) do
		local Success, Result =
			pcall(function()
				return HttpService:JSONDecode(
					game:HttpGet(
						URL
							.. "?v="
							.. tostring(
								os.time()
							)
							.. "-"
							.. tostring(
								math.random(
									1,
									99999999
								)
							)
					)
				)
			end)

		if
			Success
			and type(Result)
				== "table"
			and type(
				Result.avatars
			) == "table"
		then
			return Result
		end
	end

	return nil
end

local function GetAvatar(
	Data,
	Name
)
	if
		type(Data) ~= "table"
		or type(Data.avatars)
			~= "table"
	then
		return nil
	end

	if
		type(Name) == "string"
		and Name ~= ""
		and Data.avatars[Name]
	then
		return Data.avatars[Name]
	end

	if
		Data.selected
		and Data.avatars[
			Data.selected
		]
	then
		return Data.avatars[
			Data.selected
		]
	end

	return nil
end

local function GetScaleData(
	Avatar
)
	if
		type(Avatar.sizeProfile)
			== "table"
		and type(
			Avatar.sizeProfile.scales
		) == "table"
	then
		return Avatar.sizeProfile.scales
	end

	if
		type(Avatar.humanoid)
			== "table"
		and type(
			Avatar.humanoid.scales
		) == "table"
	then
		return Avatar.humanoid.scales
	end

	return {}
end

local function ApplyDescriptionScales(
	Description,
	Avatar
)
	local Scales =
		GetScaleData(Avatar)

	if Scales.BodyHeightScale then
		Description.HeightScale =
			Scales.BodyHeightScale
	end

	if Scales.BodyWidthScale then
		Description.WidthScale =
			Scales.BodyWidthScale
	end

	if Scales.BodyDepthScale then
		Description.DepthScale =
			Scales.BodyDepthScale
	end

	if Scales.HeadScale then
		Description.HeadScale =
			Scales.HeadScale
	end

	if Scales.BodyTypeScale then
		Description.BodyTypeScale =
			Scales.BodyTypeScale
	end

	if Scales.BodyProportionScale then
		Description.ProportionScale =
			Scales.BodyProportionScale
	end
end

local function ApplyHumanoidScales(
	Humanoid,
	Avatar
)
	local Scales =
		GetScaleData(Avatar)

	if
		type(Avatar.sizeProfile)
			== "table"
		and Avatar.sizeProfile
			.automaticScalingEnabled
			~= nil
	then
		pcall(function()
			Humanoid.AutomaticScalingEnabled =
				Avatar.sizeProfile
					.automaticScalingEnabled
		end)
	end

	for Name, Value in pairs(
		Scales
	) do
		if type(Value) == "number" then
			local Scale =
				Humanoid:FindFirstChild(
					Name
				)

			if
				Scale
				and Scale:IsA(
					"NumberValue"
				)
			then
				Scale.Value =
					Value
			end
		end
	end

	if
		type(Avatar.sizeProfile)
			== "table"
		and Avatar.sizeProfile
			.hipHeight ~= nil
	then
		Humanoid.HipHeight =
			Avatar.sizeProfile
				.hipHeight
	end
end

local BundleProperties = {
	Head = "Head",
	DynamicHead = "Head",

	Torso = "Torso",

	LeftArm = "LeftArm",
	RightArm = "RightArm",

	LeftLeg = "LeftLeg",
	RightLeg = "RightLeg"
}

local function NormalizeAssetType(
	Item
)
	local AssetType =
		Item.AssetType
		or Item.assetType

	if typeof(AssetType) == "EnumItem" then
		return AssetType.Name
	end

	if AssetType ~= nil then
		local String =
			tostring(AssetType)

		return String:match(
			"([%w]+)$"
		) or String
	end

	return ""
end

local function BundleItemProperty(
	Item
)
	local TypeName =
		NormalizeAssetType(
			Item
		)

	if BundleProperties[TypeName] then
		return BundleProperties[
			TypeName
		]
	end

	local Name =
		string.lower(
			tostring(
				Item.Name
				or Item.name
				or ""
			)
		)

	if
		Name:find(
			"dynamic head",
			1,
			true
		)
	then
		return "Head"
	end

	if
		Name:find(
			"left arm",
			1,
			true
		)
	then
		return "LeftArm"
	end

	if
		Name:find(
			"right arm",
			1,
			true
		)
	then
		return "RightArm"
	end

	if
		Name:find(
			"left leg",
			1,
			true
		)
	then
		return "LeftLeg"
	end

	if
		Name:find(
			"right leg",
			1,
			true
		)
	then
		return "RightLeg"
	end

	if
		Name:find(
			"torso",
			1,
			true
		)
	then
		return "Torso"
	end

	if
		Name:find(
			"head",
			1,
			true
		)
	then
		return "Head"
	end

	return nil
end

local function GetBundleId(
	Avatar
)
	local Id =
		tonumber(
			Avatar.bodyBundleId
		)

	if Id then
		return Id
	end

	if
		type(Avatar.bodyBundle)
			== "table"
	then
		return tonumber(
			Avatar.bodyBundle.id
		)
	end

	return nil
end

local function ApplyBodyBundle(
	Humanoid,
	Avatar
)
	local BundleId =
		GetBundleId(
			Avatar
		)

	if not BundleId then
		return false
	end

	local Success, Details =
		pcall(function()
			return AssetService:
				GetBundleDetailsAsync(
					BundleId
				)
		end)

	if
		not Success
		or type(Details)
			~= "table"
	then
		return false
	end

	local Description

	pcall(function()
		Description =
			Humanoid:
				GetAppliedDescription()
	end)

	if not Description then
		Description =
			Instance.new(
				"HumanoidDescription"
			)
	end

	pcall(function()
		Description.UseAvatarSettings =
			false
	end)

	local Found = false

	local Items =
		Details.Items
		or Details.items
		or {}

	for _, Item in ipairs(
		Items
	) do
		if type(Item) == "table" then
			local Property =
				BundleItemProperty(
					Item
				)

			local AssetId =
				tonumber(
					Item.Id
					or Item.id
				)

			if
				Property
				and AssetId
				and AssetId > 0
			then
				local Applied =
					pcall(function()
						Description[
							Property
						] = AssetId
					end)

				if Applied then
					Found = true
				end
			end
		end
	end

	if not Found then
		Description:Destroy()
		return false
	end

	ApplyDescriptionScales(
		Description,
		Avatar
	)

	local Applied =
		pcall(function()
			Humanoid:
				ApplyDescriptionResetAsync(
					Description
				)
		end)

	if not Applied then
		Applied =
			pcall(function()
				Humanoid:
					ApplyDescriptionAsync(
						Description
					)
			end)
	end

	Description:Destroy()

	return Applied
end

local function BuildBodyData(
	Avatar
)
	local Result = {}

	if
		type(Avatar.bodyParts)
			~= "table"
	then
		return Result
	end

	for _, Entry in ipairs(
		Avatar.bodyParts
	) do
		if
			type(Entry) == "table"
			and Entry.type
				== "actualBodyPart"
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
				Result[
					Data.name
				] = Data
			end
		end
	end

	return Result
end

local function CreateSurfaceAppearance(
	Parent,
	Data
)
	if type(Data) ~= "table" then
		return
	end

	local Existing =
		Parent:
			FindFirstChildOfClass(
				"SurfaceAppearance"
			)

	if Existing then
		Existing:Destroy()
	end

	local Surface =
		Instance.new(
			"SurfaceAppearance"
		)

	for _, Property in ipairs({
		"ColorMap",
		"MetalnessMap",
		"NormalMap",
		"RoughnessMap"
	}) do
		if Data[Property] then
			pcall(function()
				Surface[
					Property
				] =
					Data[Property]
			end)
		end
	end

	if Data.AlphaMode then
		pcall(function()
			Surface.AlphaMode =
				Enum.AlphaMode[
					Data.AlphaMode
				]
		end)
	end

	Surface.Parent =
		Parent
end

local function CreateWrapTarget(
	Parent,
	Data
)
	if type(Data) ~= "table" then
		return
	end

	local Existing =
		Parent:
			FindFirstChildOfClass(
				"WrapTarget"
			)

	if Existing then
		Existing:Destroy()
	end

	local Wrap =
		Instance.new(
			"WrapTarget"
		)

	Wrap.Name =
		Data.name
		or "WrapTarget"

	if Data.CageMeshId then
		pcall(function()
			Wrap.CageMeshId =
				Data.CageMeshId
		end)
	end

	if Data.CageOrigin then
		pcall(function()
			Wrap.CageOrigin =
				ToCFrame(
					Data.CageOrigin
				)
		end)
	end

	if Data.ImportOrigin then
		pcall(function()
			Wrap.ImportOrigin =
				ToCFrame(
					Data.ImportOrigin
				)
		end)
	end

	Wrap.Parent =
		Parent
end

local function CreateWrapLayer(
	Parent,
	Data
)
	if type(Data) ~= "table" then
		return
	end

	local Existing =
		Parent:
			FindFirstChildOfClass(
				"WrapLayer"
			)

	if Existing then
		Existing:Destroy()
	end

	local Wrap =
		Instance.new(
			"WrapLayer"
		)

	Wrap.Name =
		Data.name
		or "WrapLayer"

	if Data.CageMeshId then
		pcall(function()
			Wrap.CageMeshId =
				Data.CageMeshId
		end)
	end

	if Data.ReferenceMeshId then
		pcall(function()
			Wrap.ReferenceMeshId =
				Data.ReferenceMeshId
		end)
	end

	if Data.CageOrigin then
		pcall(function()
			Wrap.CageOrigin =
				ToCFrame(
					Data.CageOrigin
				)
		end)
	end

	if Data.ImportOrigin then
		pcall(function()
			Wrap.ImportOrigin =
				ToCFrame(
					Data.ImportOrigin
				)
		end)
	end

	if Data.ReferenceOrigin then
		pcall(function()
			Wrap.ReferenceOrigin =
				ToCFrame(
					Data.ReferenceOrigin
				)
		end)
	end

	if Data.Order ~= nil then
		pcall(function()
			Wrap.Order =
				Data.Order
		end)
	end

	if Data.Puffiness ~= nil then
		pcall(function()
			Wrap.Puffiness =
				Data.Puffiness
		end)
	end

	if Data.ShrinkFactor ~= nil then
		pcall(function()
			Wrap.ShrinkFactor =
				Data.ShrinkFactor
		end)
	end

	Wrap.Parent =
		Parent
end

local function CreateMeshPart(
	MeshData
)
	if type(MeshData) ~= "table" then
		return nil
	end

	local MeshId =
		GetAssetId(
			MeshData.meshId
		)

	if not MeshId then
		return nil
	end

	local Options = {}

	if MeshData.collisionFidelity then
		local Fidelity =
			Enum.CollisionFidelity[
				MeshData.collisionFidelity
			]

		if Fidelity then
			Options.CollisionFidelity =
				Fidelity
		end
	end

	if MeshData.renderFidelity then
		local Fidelity =
			Enum.RenderFidelity[
				MeshData.renderFidelity
			]

		if Fidelity then
			Options.RenderFidelity =
				Fidelity
		end
	end

	local Success, Part =
		pcall(function()
			return AssetService:
				CreateMeshPartAsync(
					Content.fromAssetId(
						MeshId
					),
					Options
				)
		end)

	if
		not Success
		or not Part
	then
		return nil
	end

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

	CreateSurfaceAppearance(
		Part,
		MeshData.surfaceAppearance
	)

	CreateWrapTarget(
		Part,
		MeshData.wrapTarget
	)

	return Part
end

local function ApplyBodyProperties(
	Part,
	Data
)
	if Data.size then
		Part.Size =
			ToVector3(
				Data.size,
				Part.Size
			)
	end

	if Data.color then
		Part.Color =
			ToColor3(
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
end

local function ApplyMeshToPart(
	Part,
	Data
)
	if
		not Part:IsA(
			"MeshPart"
		)
		or type(Data.mesh)
			~= "table"
		or Data.mesh.meshType
			~= "MeshPart"
	then
		return false
	end

	local Source =
		CreateMeshPart(
			Data.mesh
		)

	if not Source then
		return false
	end

	local Success =
		pcall(function()
			Part:ApplyMesh(
				Source
			)
		end)

	Source:Destroy()

	if not Success then
		return false
	end

	ApplyBodyProperties(
		Part,
		Data
	)

	CreateWrapTarget(
		Part,
		Data.mesh.wrapTarget
	)

	return true
end

local R6TargetNames = {
	Head = "Head",
	Torso = "Torso",

	LeftArm = "Left Arm",
	RightArm = "Right Arm",

	LeftLeg = "Left Leg",
	RightLeg = "Right Leg",

	Root = "HumanoidRootPart"
}

local function ApplySameRigBody(
	Character,
	BodyData
)
	local Index = 0

	for Name, Data in pairs(
		BodyData
	) do
		if Name ~= "HumanoidRootPart" then
			local Part =
				Character:
					FindFirstChild(
						Name
					)

			if
				Part
				and Part:IsA(
					"BasePart"
				)
			then
				ApplyBodyProperties(
					Part,
					Data
				)

				ApplyMeshToPart(
					Part,
					Data
				)
			end

			Index += 1

			if Index % 2 == 0 then
				task.wait(0.04)
			end
		end
	end
end

local function GetSlotParts(
	BodyData,
	Slot
)
	local Result = {}

	for _, Data in pairs(
		BodyData
	) do
		if Data.bodySlot == Slot then
			table.insert(
				Result,
				Data
			)
		end
	end

	return Result
end

local function FindSlotAnchor(
	Parts
)
	for _, Segment in ipairs({
		"Whole",
		"Upper",
		"Lower",
		"End"
	}) do
		for _, Data in ipairs(
			Parts
		) do
			if
				Data.segment
					== Segment
				and Data.cframe
			then
				return Data
			end
		end
	end

	return Parts[1]
end

local function ClearCrossRigVisuals(
	Character
)
	local Folder =
		Character:
			FindFirstChild(
				"CatalogBodyVisuals"
			)

	if Folder then
		Folder:Destroy()
	end
end

local function ApplyCrossRigBody(
	Character,
	BodyData
)
	ClearCrossRigVisuals(
		Character
	)

	local Folder =
		Instance.new("Folder")

	Folder.Name =
		"CatalogBodyVisuals"

	Folder.Parent =
		Character

	local Slots = {
		"Torso",
		"LeftArm",
		"RightArm",
		"LeftLeg",
		"RightLeg"
	}

	for _, Slot in ipairs(
		Slots
	) do
		local TargetName =
			R6TargetNames[Slot]

		local Target =
			Character:
				FindFirstChild(
					TargetName
				)

		if
			Target
			and Target:IsA(
				"BasePart"
			)
		then
			local Parts =
				GetSlotParts(
					BodyData,
					Slot
				)

			local Anchor =
				FindSlotAnchor(
					Parts
				)

			if
				Anchor
				and Anchor.cframe
			then
				local AnchorCFrame =
					ToCFrame(
						Anchor.cframe
					)

				for _, Data in ipairs(
					Parts
				) do
					if
						type(Data.mesh)
							== "table"
						and Data.mesh.meshType
							== "MeshPart"
						and Data.cframe
					then
						local Visual =
							CreateMeshPart(
								Data.mesh
							)

						if Visual then
							Visual.Name =
								"Catalog_"
								.. Data.name

							ApplyBodyProperties(
								Visual,
								Data
							)

							Visual.CanCollide =
								false

							Visual.CanTouch =
								false

							Visual.CanQuery =
								false

							Visual.Massless =
								true

							local SourceCF =
								ToCFrame(
									Data.cframe
								)

							local Relative =
								AnchorCFrame:
									ToObjectSpace(
										SourceCF
									)

							Visual.CFrame =
								Target.CFrame
								* Relative

							Visual.Parent =
								Folder

							local Weld =
								Instance.new(
									"Weld"
								)

							Weld.Name =
								"CatalogBodyWeld"

							Weld.Part0 =
								Target

							Weld.Part1 =
								Visual

							Weld.C0 =
								Target.CFrame:
									ToObjectSpace(
										Visual.CFrame
									)

							Weld.C1 =
								CFrame.new()

							Weld.Parent =
								Visual
						end

						task.wait(0.04)
					end
				end
			end
		end
	end
end

local function ApplySavedBody(
	Character,
	Humanoid,
	Avatar,
	BundleApplied
)
	local BodyData =
		BuildBodyData(
			Avatar
		)

	if next(BodyData) == nil then
		return
	end

	local SourceRig =
		Avatar.sourceRig

	if not SourceRig then
		if
			type(Avatar.humanoid)
				== "table"
		then
			SourceRig =
				Avatar.humanoid.rigType
		end
	end

	local TargetRig =
		Humanoid.RigType.Name

	if SourceRig == TargetRig then
		if not BundleApplied then
			ApplySameRigBody(
				Character,
				BodyData
			)
		else
			for Name, Data in pairs(
				BodyData
			) do
				local Part =
					Character:
						FindFirstChild(
							Name
						)

				if
					Part
					and Part:IsA(
						"BasePart"
					)
				then
					ApplyBodyProperties(
						Part,
						Data
					)
				end
			end
		end

	elseif
		SourceRig == "R15"
		and TargetRig == "R6"
	then
		ApplyCrossRigBody(
			Character,
			BodyData
		)
	end
end

local function BuildSavedAttachmentMap(
	Avatar
)
	local Result = {}

	local BodyData =
		BuildBodyData(
			Avatar
		)

	for _, Data in pairs(
		BodyData
	) do
		if
			type(Data.attachments)
				== "table"
		then
			for _, Attachment in ipairs(
				Data.attachments
			) do
				if Attachment.name then
					Result[
						Attachment.name
					] = Attachment
				end
			end
		end
	end

	return Result
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
			Object:IsA(
				"Attachment"
			)
			and Object.Name == Name
			and (
				not Ignore
				or not Object:
					IsDescendantOf(
						Ignore
					)
			)
		then
			return Object
		end
	end

	return nil
end

local function GetFallbackTargetPart(
	Character,
	Humanoid,
	SavedAttachment
)
	if
		type(SavedAttachment)
			~= "table"
	then
		return nil
	end

	local Name

	if
		Humanoid.RigType
		== Enum.HumanoidRigType.R6
	then
		Name =
			SavedAttachment.targetR6
	else
		Name =
			SavedAttachment.targetR15
	end

	if not Name then
		return nil
	end

	local Part =
		Character:
			FindFirstChild(
				Name
			)

	if
		Part
		and Part:IsA(
			"BasePart"
		)
	then
		return Part
	end

	return nil
end

local function ApplyHandleAttachments(
	Handle,
	Attachments
)
	if type(Attachments) ~= "table" then
		return
	end

	for _, Data in ipairs(
		Attachments
	) do
		if Data.name then
			local Attachment =
				Instance.new(
					"Attachment"
				)

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

local function GetMeshScale(
	HandleData,
	MeshData
)
	if
		type(MeshData.meshSize)
			== "table"
		and type(HandleData.size)
			== "table"
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
				Size.X
					/ MeshSize.X,

				Size.Y
					/ MeshSize.Y,

				Size.Z
					/ MeshSize.Z
			)
		end
	end

	if MeshData.scale then
		return ToVector3(
			MeshData.scale,
			Vector3.new(
				1,
				1,
				1
			)
		)
	end

	return Vector3.new(
		1,
		1,
		1
	)
end

local function ApplyHandleProperties(
	Handle,
	Data
)
	if Data.size then
		Handle.Size =
			ToVector3(
				Data.size,
				Vector3.new(
					1,
					1,
					1
				)
			)
	end

	if Data.color then
		Handle.Color =
			ToColor3(
				Data.color
			)
	end

	if Data.transparency ~= nil then
		Handle.Transparency =
			Data.transparency
	end

	if Data.reflectance ~= nil then
		Handle.Reflectance =
			Data.reflectance
	end

	if Data.material then
		pcall(function()
			Handle.Material =
				Enum.Material[
					Data.material
				]
		end)
	end

	Handle.CanCollide =
		false

	Handle.CanTouch =
		false

	Handle.CanQuery =
		false

	Handle.Massless =
		true
end

local function CreateNormalHandle(
	HandleData
)
	local Handle =
		Instance.new(
			"Part"
		)

	Handle.Name =
		"Handle"

	ApplyHandleProperties(
		Handle,
		HandleData
	)

	local MeshData =
		HandleData.mesh

	if
		type(MeshData) == "table"
		and MeshData.meshId
	then
		local Mesh =
			Instance.new(
				"SpecialMesh"
			)

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

	ApplyHandleAttachments(
		Handle,
		HandleData.attachments
	)

	return Handle
end

local function CreateLayeredHandle(
	HandleData
)
	local MeshData =
		HandleData.mesh

	local Handle

	if type(MeshData) == "table" then
		Handle =
			CreateMeshPart(
				MeshData
			)
	end

	if not Handle then
		return CreateNormalHandle(
			HandleData
		)
	end

	Handle.Name =
		"Handle"

	ApplyHandleProperties(
		Handle,
		HandleData
	)

	ApplyHandleAttachments(
		Handle,
		HandleData.attachments
	)

	CreateWrapLayer(
		Handle,
		HandleData.wrapLayer
	)

	return Handle
end

local function ManualWeldAccessory(
	Character,
	Humanoid,
	Accessory,
	Handle,
	SavedAttachmentMap
)
	local HandleAttachment =
		Handle:
			FindFirstChildOfClass(
				"Attachment"
			)

	if not HandleAttachment then
		return false
	end

	local TargetAttachment =
		FindCharacterAttachment(
			Character,
			HandleAttachment.Name,
			Accessory
		)

	if
		TargetAttachment
		and TargetAttachment.Parent
		and TargetAttachment.Parent:
			IsA("BasePart")
	then
		local TargetPart =
			TargetAttachment.Parent

		Handle.CFrame =
			TargetPart.CFrame
			* TargetAttachment.CFrame
			* HandleAttachment
				.CFrame:Inverse()

		local Weld =
			Instance.new(
				"Weld"
			)

		Weld.Name =
			"AccessoryWeld"

		Weld.Part0 =
			Handle

		Weld.Part1 =
			TargetPart

		Weld.C0 =
			HandleAttachment.CFrame

		Weld.C1 =
			TargetAttachment.CFrame

		Weld.Parent =
			Handle

		return true
	end

	local SavedAttachment =
		SavedAttachmentMap[
			HandleAttachment.Name
		]

	local TargetPart =
		GetFallbackTargetPart(
			Character,
			Humanoid,
			SavedAttachment
		)

	if
		not TargetPart
		or not SavedAttachment
	then
		return false
	end

	local TargetCF =
		SavedAttachment.cframe
		and ToCFrame(
			SavedAttachment.cframe
		)
		or CFrame.new()

	Handle.CFrame =
		TargetPart.CFrame
		* TargetCF
		* HandleAttachment
			.CFrame:Inverse()

	local Weld =
		Instance.new(
			"Weld"
		)

	Weld.Name =
		"AccessoryWeld"

	Weld.Part0 =
		Handle

	Weld.Part1 =
		TargetPart

	Weld.C0 =
		HandleAttachment.CFrame

	Weld.C1 =
		TargetCF

	Weld.Parent =
		Handle

	return true
end

local function CreateAccessory(
	Character,
	Humanoid,
	Data,
	SavedAttachmentMap
)
	if
		type(Data) ~= "table"
		or type(Data.handle)
			~= "table"
	then
		return
	end

	local Accessory =
		Instance.new(
			"Accessory"
		)

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

	local HandleData =
		Data.handle

	local IsLayered =
		type(
			HandleData.wrapLayer
		) == "table"

	local Handle

	if IsLayered then
		Handle =
			CreateLayeredHandle(
				HandleData
			)
	else
		Handle =
			CreateNormalHandle(
				HandleData
			)
	end

	if not Handle then
		Accessory:Destroy()
		return
	end

	Handle.Parent =
		Accessory

	if IsLayered then
		local Added =
			pcall(function()
				Humanoid:AddAccessory(
					Accessory
				)
			end)

		if not Added then
			Accessory.Parent =
				Character

			ManualWeldAccessory(
				Character,
				Humanoid,
				Accessory,
				Handle,
				SavedAttachmentMap
			)
		end
	else
		Accessory.Parent =
			Character

		ManualWeldAccessory(
			Character,
			Humanoid,
			Accessory,
			Handle,
			SavedAttachmentMap
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

	if
		type(Avatar.accessories)
			~= "table"
	then
		return
	end

	local SavedAttachmentMap =
		BuildSavedAttachmentMap(
			Avatar
		)

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
					SavedAttachmentMap
				)
			end
		end

		if Index % 2 == 0 then
			task.wait(0.04)
		end
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
			or Object:IsA(
				"ShirtGraphic"
			)
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
		type(Clothing.shirt)
			== "table"
		and Clothing.shirt.texture
	then
		local Shirt =
			Instance.new(
				"Shirt"
			)

		Shirt.Name =
			Clothing.shirt.name
			or "Shirt"

		Shirt.ShirtTemplate =
			Clothing.shirt.texture

		Shirt.Parent =
			Character
	end

	if
		type(Clothing.pants)
			== "table"
		and Clothing.pants.texture
	then
		local Pants =
			Instance.new(
				"Pants"
			)

		Pants.Name =
			Clothing.pants.name
			or "Pants"

		Pants.PantsTemplate =
			Clothing.pants.texture

		Pants.Parent =
			Character
	end

	if
		type(Clothing.tshirt)
			== "table"
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
		Character:
			FindFirstChildOfClass(
				"BodyColors"
			)

	if not Colors then
		Colors =
			Instance.new(
				"BodyColors"
			)

		Colors.Parent =
			Character
	end

	if Data.head then
		Colors.HeadColor3 =
			ToColor3(
				Data.head
			)
	end

	if Data.torso then
		Colors.TorsoColor3 =
			ToColor3(
				Data.torso
			)
	end

	if Data.leftArm then
		Colors.LeftArmColor3 =
			ToColor3(
				Data.leftArm
			)
	end

	if Data.rightArm then
		Colors.RightArmColor3 =
			ToColor3(
				Data.rightArm
			)
	end

	if Data.leftLeg then
		Colors.LeftLegColor3 =
			ToColor3(
				Data.leftLeg
			)
	end

	if Data.rightLeg then
		Colors.RightLegColor3 =
			ToColor3(
				Data.rightLeg
			)
	end
end

local function ApplyDecals(
	Character,
	Avatar
)
	if
		type(Avatar.decals)
			~= "table"
	then
		return
	end

	for _, Existing in ipairs(
		Character:GetDescendants()
	) do
		if Existing:IsA("Decal") then
			Existing:Destroy()
		end
	end

	for _, Data in ipairs(
		Avatar.decals
	) do
		if
			type(Data) == "table"
			and Data.parent
		then
			local Parent =
				Character:
					FindFirstChild(
						Data.parent,
						true
					)

			if Parent then
				local Decal =
					Instance.new(
						"Decal"
					)

				Decal.Name =
					Data.name
					or "face"

				Decal.Texture =
					Data.texture
					or ""

				if
					Data.transparency
						~= nil
				then
					Decal.Transparency =
						Data.transparency
				end

				if Data.color then
					Decal.Color3 =
						ToColor3(
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

				Decal.Parent =
					Parent
			end
		end
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
	if
		type(Avatar.animations)
			~= "table"
	then
		return
	end

	local Animate =
		Character:
			FindFirstChild(
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
			local Parent =
				Animate:
					FindFirstChild(
						Saved.parent
					)

			if Parent then
				local Animation =
					Parent:
						FindFirstChild(
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
		Humanoid:
			FindFirstChildOfClass(
				"Animator"
			)

	if Animator then
		for _, Track in ipairs(
			Animator:
				GetPlayingAnimationTracks()
		) do
			pcall(function()
				Track:Stop(
					0.05
				)
			end)
		end
	end
end

local Applying = false
local CurrentAvatarName = nil

local function ApplyAvatar(
	AvatarName
)
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
		or Player.CharacterAdded:
			Wait()

	local Humanoid =
		Character:
			FindFirstChildOfClass(
				"Humanoid"
			)

	if not Humanoid then
		Humanoid =
			Character:
				WaitForChild(
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

	ClearCrossRigVisuals(
		Character
	)

	ApplyHumanoidScales(
		Humanoid,
		Avatar
	)

	local BundleApplied =
		ApplyBodyBundle(
			Humanoid,
			Avatar
		)

	if BundleApplied then
		task.wait(0.35)

		Character =
			Player.Character
			or Character

		Humanoid =
			Character:
				FindFirstChildOfClass(
					"Humanoid"
				)
			or Humanoid

		ApplyHumanoidScales(
			Humanoid,
			Avatar
		)
	end

	ApplySavedBody(
		Character,
		Humanoid,
		Avatar,
		BundleApplied
	)

	ApplyHumanoid(
		Humanoid,
		Avatar
	)

	ApplyBodyColors(
		Character,
		Avatar
	)

	ApplyClothing(
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

	return true
end

if
	Environment
		.CatalogServiceCharacterConnection
then
	pcall(function()
		Environment
			.CatalogServiceCharacterConnection:
			Disconnect()
	end)
end

Environment
	.CatalogServiceCharacterConnection =
	Player.CharacterAdded:
		Connect(function(Character)
			Character:
				WaitForChild(
					"Humanoid"
				)

			task.wait(
				0.8
			)

			if CurrentAvatarName then
				ApplyAvatar(
					CurrentAvatarName
				)
			end
		end)

Environment.CatalogServiceApply =
	ApplyAvatar

return ApplyAvatar
