local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer

local Base64Chars =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(Data)
	return (
		(Data:gsub(".", function(Character)
			local Byte = Character:byte()
			local Bits = ""

			for Index = 8, 1, -1 do
				Bits ..=
					Byte % 2 ^ Index
						- Byte % 2 ^ (Index - 1)
						> 0
					and "1"
					or "0"
			end

			return Bits
		end) .. "0000")
			:gsub(
				"%d%d%d?%d?%d?%d?",
				function(Bits)
					if #Bits < 6 then
						return ""
					end

					local Value = 0

					for Index = 1, 6 do
						if Bits:sub(Index, Index) == "1" then
							Value +=
								2 ^ (6 - Index)
						end
					end

					return Base64Chars:sub(
						Value + 1,
						Value + 1
					)
				end
			)
			.. ({
				"",
				"==",
				"="
			})[#Data % 3 + 1]
	)
end

local function GetProperty(Object, Property)
	local Success, Value =
		pcall(function()
			return Object[Property]
		end)

	if Success then
		return Value
	end

	return nil
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

local function EncodeJSON(Data)
	return Base64Encode(
		HttpService:JSONEncode(Data)
	)
end

local BodyDefinitions = {
	Head = {
		r6 = "Head",
		r15 = {
			"Head"
		}
	},

	Torso = {
		r6 = "Torso",
		r15 = {
			"UpperTorso",
			"LowerTorso"
		}
	},

	LeftArm = {
		r6 = "Left Arm",
		r15 = {
			"LeftUpperArm",
			"LeftLowerArm",
			"LeftHand"
		}
	},

	RightArm = {
		r6 = "Right Arm",
		r15 = {
			"RightUpperArm",
			"RightLowerArm",
			"RightHand"
		}
	},

	LeftLeg = {
		r6 = "Left Leg",
		r15 = {
			"LeftUpperLeg",
			"LeftLowerLeg",
			"LeftFoot"
		}
	},

	RightLeg = {
		r6 = "Right Leg",
		r15 = {
			"RightUpperLeg",
			"RightLowerLeg",
			"RightFoot"
		}
	},

	Root = {
		r6 = "HumanoidRootPart",
		r15 = {
			"HumanoidRootPart"
		}
	}
}

local PartDefinitions = {
	Head = {
		slot = "Head",
		segment = "Whole"
	},

	Torso = {
		slot = "Torso",
		segment = "Whole"
	},

	["Left Arm"] = {
		slot = "LeftArm",
		segment = "Whole"
	},

	["Right Arm"] = {
		slot = "RightArm",
		segment = "Whole"
	},

	["Left Leg"] = {
		slot = "LeftLeg",
		segment = "Whole"
	},

	["Right Leg"] = {
		slot = "RightLeg",
		segment = "Whole"
	},

	HumanoidRootPart = {
		slot = "Root",
		segment = "Whole"
	},

	UpperTorso = {
		slot = "Torso",
		segment = "Upper"
	},

	LowerTorso = {
		slot = "Torso",
		segment = "Lower"
	},

	LeftUpperArm = {
		slot = "LeftArm",
		segment = "Upper"
	},

	LeftLowerArm = {
		slot = "LeftArm",
		segment = "Lower"
	},

	LeftHand = {
		slot = "LeftArm",
		segment = "End"
	},

	RightUpperArm = {
		slot = "RightArm",
		segment = "Upper"
	},

	RightLowerArm = {
		slot = "RightArm",
		segment = "Lower"
	},

	RightHand = {
		slot = "RightArm",
		segment = "End"
	},

	LeftUpperLeg = {
		slot = "LeftLeg",
		segment = "Upper"
	},

	LeftLowerLeg = {
		slot = "LeftLeg",
		segment = "Lower"
	},

	LeftFoot = {
		slot = "LeftLeg",
		segment = "End"
	},

	RightUpperLeg = {
		slot = "RightLeg",
		segment = "Upper"
	},

	RightLowerLeg = {
		slot = "RightLeg",
		segment = "Lower"
	},

	RightFoot = {
		slot = "RightLeg",
		segment = "End"
	}
}

local AttachmentTargets = {
	HatAttachment = {
		r6 = "Head",
		r15 = "Head"
	},

	HairAttachment = {
		r6 = "Head",
		r15 = "Head"
	},

	FaceFrontAttachment = {
		r6 = "Head",
		r15 = "Head"
	},

	FaceCenterAttachment = {
		r6 = "Head",
		r15 = "Head"
	},

	NeckAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	BodyFrontAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	BodyBackAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	LeftCollarAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	RightCollarAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	LeftShoulderAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	RightShoulderAttachment = {
		r6 = "Torso",
		r15 = "UpperTorso"
	},

	WaistFrontAttachment = {
		r6 = "Torso",
		r15 = "LowerTorso"
	},

	WaistBackAttachment = {
		r6 = "Torso",
		r15 = "LowerTorso"
	},

	WaistCenterAttachment = {
		r6 = "Torso",
		r15 = "LowerTorso"
	},

	LeftGripAttachment = {
		r6 = "Left Arm",
		r15 = "LeftHand"
	},

	RightGripAttachment = {
		r6 = "Right Arm",
		r15 = "RightHand"
	},

	LeftFootAttachment = {
		r6 = "Left Leg",
		r15 = "LeftFoot"
	},

	RightFootAttachment = {
		r6 = "Right Leg",
		r15 = "RightFoot"
	}
}

local function GetPartDefinition(Name)
	return PartDefinitions[Name]
end

local function GetSlot(Name)
	local Definition =
		GetPartDefinition(Name)

	if Definition then
		return Definition.slot
	end

	return nil
end

local function DefaultR6Target(
	SourcePart,
	AttachmentName
)
	local AttachmentDefinition =
		AttachmentTargets[
			AttachmentName
		]

	if AttachmentDefinition then
		return AttachmentDefinition.r6
	end

	local Definition =
		GetPartDefinition(
			SourcePart
		)

	if not Definition then
		return SourcePart
	end

	local BodyDefinition =
		BodyDefinitions[
			Definition.slot
		]

	if BodyDefinition then
		return BodyDefinition.r6
	end

	return SourcePart
end

local function DefaultR15Target(
	SourcePart,
	AttachmentName
)
	local AttachmentDefinition =
		AttachmentTargets[
			AttachmentName
		]

	if AttachmentDefinition then
		return AttachmentDefinition.r15
	end

	local Definition =
		GetPartDefinition(
			SourcePart
		)

	if not Definition then
		return SourcePart
	end

	if Definition.slot == "Head" then
		return "Head"
	end

	if Definition.slot == "Root" then
		return "HumanoidRootPart"
	end

	if Definition.slot == "Torso" then
		if
			Definition.segment == "Lower"
			or (
				AttachmentName
				and AttachmentName:find(
					"Waist"
				)
			)
			or (
				AttachmentName
				and AttachmentName:find(
					"Hip"
				)
			)
		then
			return "LowerTorso"
		end

		return "UpperTorso"
	end

	if Definition.slot == "LeftArm" then
		if
			Definition.segment == "End"
			or AttachmentName
				== "LeftGripAttachment"
		then
			return "LeftHand"
		end

		if Definition.segment == "Lower" then
			return "LeftLowerArm"
		end

		return "LeftUpperArm"
	end

	if Definition.slot == "RightArm" then
		if
			Definition.segment == "End"
			or AttachmentName
				== "RightGripAttachment"
		then
			return "RightHand"
		end

		if Definition.segment == "Lower" then
			return "RightLowerArm"
		end

		return "RightUpperArm"
	end

	if Definition.slot == "LeftLeg" then
		if
			Definition.segment == "End"
			or AttachmentName
				== "LeftFootAttachment"
		then
			return "LeftFoot"
		end

		if Definition.segment == "Lower" then
			return "LeftLowerLeg"
		end

		return "LeftUpperLeg"
	end

	if Definition.slot == "RightLeg" then
		if
			Definition.segment == "End"
			or AttachmentName
				== "RightFootAttachment"
		then
			return "RightFoot"
		end

		if Definition.segment == "Lower" then
			return "RightLowerLeg"
		end

		return "RightUpperLeg"
	end

	return SourcePart
end

local function ExtractAttachment(
	Attachment,
	SourcePart
)
	return {
		name =
			Attachment.Name,

		sourcePart =
			SourcePart,

		bodySlot =
			GetSlot(
				SourcePart
			),

		targetR6 =
			DefaultR6Target(
				SourcePart,
				Attachment.Name
			),

		targetR15 =
			DefaultR15Target(
				SourcePart,
				Attachment.Name
			),

		cframe =
			CFrameToTable(
				Attachment.CFrame
			),

		position =
			VectorToTable(
				Attachment.Position
			),

		orientation =
			VectorToTable(
				Attachment.Orientation
			)
	}
end

local function ExtractAttachments(
	Object,
	SourcePart
)
	local Result = {}

	for _, Child in ipairs(
		Object:GetChildren()
	) do
		if Child:IsA("Attachment") then
			table.insert(
				Result,
				ExtractAttachment(
					Child,
					SourcePart
				)
			)
		end
	end

	return Result
end

local function ExtractSurfaceAppearance(
	Object
)
	local Surface =
		Object:FindFirstChildOfClass(
			"SurfaceAppearance"
		)

	if not Surface then
		return nil
	end

	local Data = {
		name =
			Surface.Name
	}

	for _, Property in ipairs({
		"ColorMap",
		"MetalnessMap",
		"NormalMap",
		"RoughnessMap"
	}) do
		local Value =
			GetProperty(
				Surface,
				Property
			)

		if type(Value) == "string" then
			Data[Property] =
				Value
		end
	end

	local AlphaMode =
		GetProperty(
			Surface,
			"AlphaMode"
		)

	if AlphaMode then
		Data.AlphaMode =
			AlphaMode.Name
	end

	return Data
end

local function ExtractWrapLayer(
	Object
)
	local Wrap =
		Object:FindFirstChildOfClass(
			"WrapLayer"
		)

	if not Wrap then
		return nil
	end

	local Data = {
		name =
			Wrap.Name
	}

	for _, Property in ipairs({
		"CageMeshId",
		"ReferenceMeshId"
	}) do
		local Value =
			GetProperty(
				Wrap,
				Property
			)

		if type(Value) == "string" then
			Data[Property] =
				Value
		end
	end

	for _, Property in ipairs({
		"Order",
		"Puffiness",
		"ShrinkFactor"
	}) do
		local Value =
			GetProperty(
				Wrap,
				Property
			)

		if type(Value) == "number" then
			Data[Property] =
				Value
		end
	end

	for _, Property in ipairs({
		"CageOrigin",
		"ImportOrigin",
		"ReferenceOrigin"
	}) do
		local Value =
			GetProperty(
				Wrap,
				Property
			)

		if typeof(Value) == "CFrame" then
			Data[Property] =
				CFrameToTable(
					Value
				)
		end
	end

	return Data
end

local function ExtractWrapTarget(
	Object
)
	local Wrap =
		Object:FindFirstChildOfClass(
			"WrapTarget"
		)

	if not Wrap then
		return nil
	end

	local Data = {
		name =
			Wrap.Name
	}

	local CageMeshId =
		GetProperty(
			Wrap,
			"CageMeshId"
		)

	if type(CageMeshId) == "string" then
		Data.CageMeshId =
			CageMeshId
	end

	for _, Property in ipairs({
		"CageOrigin",
		"ImportOrigin"
	}) do
		local Value =
			GetProperty(
				Wrap,
				Property
			)

		if typeof(Value) == "CFrame" then
			Data[Property] =
				CFrameToTable(
					Value
				)
		end
	end

	return Data
end

local function ExtractMesh(BasePart)
	local Data = {}

	if BasePart:IsA("MeshPart") then
		Data.meshType =
			"MeshPart"

		Data.meshId =
			BasePart.MeshId

		Data.textureId =
			BasePart.TextureID

		local MeshSize =
			GetProperty(
				BasePart,
				"MeshSize"
			)

		if typeof(MeshSize) == "Vector3" then
			Data.meshSize =
				VectorToTable(
					MeshSize
				)
		end

		local RenderFidelity =
			GetProperty(
				BasePart,
				"RenderFidelity"
			)

		if RenderFidelity then
			Data.renderFidelity =
				RenderFidelity.Name
		end

		local CollisionFidelity =
			GetProperty(
				BasePart,
				"CollisionFidelity"
			)

		if CollisionFidelity then
			Data.collisionFidelity =
				CollisionFidelity.Name
		end

		local DoubleSided =
			GetProperty(
				BasePart,
				"DoubleSided"
			)

		if DoubleSided ~= nil then
			Data.doubleSided =
				DoubleSided
		end

		Data.surfaceAppearance =
			ExtractSurfaceAppearance(
				BasePart
			)

		Data.wrapTarget =
			ExtractWrapTarget(
				BasePart
			)

		return Data
	end

	local Mesh =
		BasePart:FindFirstChildOfClass(
			"SpecialMesh"
		)

	if Mesh then
		Data.meshType =
			"SpecialMesh"

		Data.meshId =
			Mesh.MeshId

		Data.textureId =
			Mesh.TextureId

		Data.scale =
			VectorToTable(
				Mesh.Scale
			)

		Data.offset =
			VectorToTable(
				Mesh.Offset
			)

		Data.vertexColor =
			VectorToTable(
				Mesh.VertexColor
			)

		Data.meshEnum =
			Mesh.MeshType.Name

		return Data
	end

	Data.meshType =
		"Part"

	return Data
end

local function GetAssetId(Object)
	for _, Property in ipairs({
		"SourceAssetId",
		"AssetId"
	}) do
		local Value =
			GetProperty(
				Object,
				Property
			)

		if
			type(Value) == "number"
			and Value > 0
		then
			return Value
		end
	end

	return nil
end

local function ExtractJoint(Object)
	local Data = {
		name =
			Object.Name,

		className =
			Object.ClassName,

		parent =
			Object.Parent
			and Object.Parent.Name
			or ""
	}

	local Part0 =
		GetProperty(
			Object,
			"Part0"
		)

	local Part1 =
		GetProperty(
			Object,
			"Part1"
		)

	if Part0 then
		Data.part0 =
			Part0.Name
	end

	if Part1 then
		Data.part1 =
			Part1.Name
	end

	local C0 =
		GetProperty(
			Object,
			"C0"
		)

	local C1 =
		GetProperty(
			Object,
			"C1"
		)

	if typeof(C0) == "CFrame" then
		Data.c0 =
			CFrameToTable(C0)
	end

	if typeof(C1) == "CFrame" then
		Data.c1 =
			CFrameToTable(C1)
	end

	if Object:IsA("Motor6D") then
		Data.transform =
			CFrameToTable(
				Object.Transform
			)
	end

	return Data
end

local function ExtractAccessory(
	Accessory
)
	local AccessoryType =
		GetProperty(
			Accessory,
			"AccessoryType"
		)

	local Data = {
		name =
			Accessory.Name,

		className =
			Accessory.ClassName,

		accessoryType =
			AccessoryType
			and AccessoryType.Name
			or "Unknown"
	}

	local AssetId =
		GetAssetId(
			Accessory
		)

	if AssetId then
		Data.avatarItemId =
			AssetId
	end

	local Handle =
		Accessory:FindFirstChild(
			"Handle"
		)

	if
		not Handle
		or not Handle:IsA("BasePart")
	then
		return Data
	end

	local HandleAssetId =
		GetAssetId(
			Handle
		)

	if
		not Data.avatarItemId
		and HandleAssetId
	then
		Data.avatarItemId =
			HandleAssetId
	end

	Data.handle = {
		className =
			Handle.ClassName,

		size =
			VectorToTable(
				Handle.Size
			),

		cframe =
			CFrameToTable(
				Handle.CFrame
			),

		color =
			ColorToTable(
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
			ExtractMesh(
				Handle
			),

		attachments =
			ExtractAttachments(
				Handle,
				nil
			),

		wrapLayer =
			ExtractWrapLayer(
				Handle
			),

		welds = {}
	}

	for _, Child in ipairs(
		Handle:GetChildren()
	) do
		if
			Child:IsA("Weld")
			or Child:IsA("Motor6D")
			or Child:IsA("WeldConstraint")
		then
			table.insert(
				Data.handle.welds,
				ExtractJoint(
					Child
				)
			)
		end
	end

	return Data
end

local function ExtractBodyPart(
	Part
)
	local Definition =
		GetPartDefinition(
			Part.Name
		)

	local Data = {
		name =
			Part.Name,

		className =
			Part.ClassName,

		bodySlot =
			Definition
			and Definition.slot
			or nil,

		segment =
			Definition
			and Definition.segment
			or nil,

		targetR6 =
			DefaultR6Target(
				Part.Name
			),

		targetR15 =
			DefaultR15Target(
				Part.Name
			),

		size =
			VectorToTable(
				Part.Size
			),

		cframe =
			CFrameToTable(
				Part.CFrame
			),

		color =
			ColorToTable(
				Part.Color
			),

		transparency =
			Part.Transparency,

		reflectance =
			Part.Reflectance,

		material =
			Part.Material.Name,

		mesh =
			ExtractMesh(
				Part
			),

		attachments =
			ExtractAttachments(
				Part,
				Part.Name
			),

		joints = {}
	}

	local AssetId =
		GetAssetId(
			Part
		)

	if AssetId then
		Data.avatarItemId =
			AssetId
	end

	for _, Child in ipairs(
		Part:GetChildren()
	) do
		if
			Child:IsA("Motor6D")
			or Child:IsA("Weld")
			or Child:IsA("WeldConstraint")
		then
			table.insert(
				Data.joints,
				ExtractJoint(
					Child
				)
			)
		end
	end

	return Data
end

local function ExtractBodyMap(
	Character,
	Humanoid
)
	local Map = {
		sourceRig =
			Humanoid.RigType.Name,

		slots = {}
	}

	for Slot, Definition in pairs(
		BodyDefinitions
	) do
		local Entry = {
			r6Target =
				Definition.r6,

			r15Targets =
				Definition.r15,

			sourceParts = {}
		}

		if
			Humanoid.RigType
			== Enum.HumanoidRigType.R6
		then
			local Part =
				Character:FindFirstChild(
					Definition.r6
				)

			if
				Part
				and Part:IsA("BasePart")
			then
				table.insert(
					Entry.sourceParts,
					Definition.r6
				)
			end

		else
			for _, Name in ipairs(
				Definition.r15
			) do
				local Part =
					Character:FindFirstChild(
						Name
					)

				if
					Part
					and Part:IsA("BasePart")
				then
					table.insert(
						Entry.sourceParts,
						Name
					)
				end
			end
		end

		Map.slots[Slot] =
			Entry
	end

	return Map
end

local function ExtractCharacterMeshes(
	Character
)
	local Result = {}

	for _, Object in ipairs(
		Character:GetChildren()
	) do
		if Object:IsA("CharacterMesh") then
			local Data = {
				name =
					Object.Name,

				bodyPart =
					Object.BodyPart.Name
			}

			for _, Property in ipairs({
				"MeshId",
				"BaseTextureId",
				"OverlayTextureId"
			}) do
				local Value =
					GetProperty(
						Object,
						Property
					)

				if Value ~= nil then
					Data[Property] =
						Value
				end
			end

			table.insert(
				Result,
				Data
			)
		end
	end

	return Result
end

local function ExtractJointMap(
	Character
)
	local Result = {}

	for _, Object in ipairs(
		Character:GetDescendants()
	) do
		if
			Object:IsA("Motor6D")
			or Object:IsA("Weld")
			or Object:IsA("WeldConstraint")
		then
			table.insert(
				Result,
				ExtractJoint(
					Object
				)
			)
		end
	end

	return Result
end

local function ExtractClothing(
	Character
)
	local Result = {}

	for _, Object in ipairs(
		Character:GetChildren()
	) do
		if Object:IsA("Shirt") then
			Result.shirt = {
				name =
					Object.Name,

				texture =
					Object.ShirtTemplate
			}

		elseif Object:IsA("Pants") then
			Result.pants = {
				name =
					Object.Name,

				texture =
					Object.PantsTemplate
			}

		elseif Object:IsA("ShirtGraphic") then
			Result.tshirt = {
				name =
					Object.Name,

				texture =
					Object.Graphic
			}
		end
	end

	return Result
end

local function ExtractBodyColors(
	Character
)
	local Colors =
		Character:FindFirstChildOfClass(
			"BodyColors"
		)

	if not Colors then
		return nil
	end

	return {
		head =
			ColorToTable(
				Colors.HeadColor3
			),

		torso =
			ColorToTable(
				Colors.TorsoColor3
			),

		leftArm =
			ColorToTable(
				Colors.LeftArmColor3
			),

		rightArm =
			ColorToTable(
				Colors.RightArmColor3
			),

		leftLeg =
			ColorToTable(
				Colors.LeftLegColor3
			),

		rightLeg =
			ColorToTable(
				Colors.RightLegColor3
			)
	}
end

local function ExtractDecals(
	Character
)
	local Result = {}

	for _, Object in ipairs(
		Character:GetDescendants()
	) do
		if Object:IsA("Decal") then
			table.insert(
				Result,
				{
					name =
						Object.Name,

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
				}
			)
		end
	end

	return Result
end

local function ExtractAnimations(
	Character
)
	local Result = {}

	for _, Object in ipairs(
		Character:GetDescendants()
	) do
		if Object:IsA("Animation") then
			table.insert(
				Result,
				{
					name =
						Object.Name,

					parent =
						Object.Parent
						and Object.Parent.Name
						or "",

					animationId =
						Object.AnimationId
				}
			)
		end
	end

	return Result
end

local function ExtractPlayingAnimations(
	Humanoid
)
	local Result = {}

	local Animator =
		Humanoid:FindFirstChildOfClass(
			"Animator"
		)

	if not Animator then
		return Result
	end

	for _, Track in ipairs(
		Animator:GetPlayingAnimationTracks()
	) do
		local Animation =
			Track.Animation

		table.insert(
			Result,
			{
				name =
					Track.Name,

				animationId =
					Animation
					and Animation.AnimationId
					or "",

				priority =
					Track.Priority.Name,

				speed =
					Track.Speed,

				timePosition =
					Track.TimePosition,

				weight =
					Track.WeightCurrent,

				looped =
					Track.Looped
			}
		)
	end

	return Result
end

local function ExtractScaleValues(
	Humanoid
)
	local Result = {}

	for _, Object in ipairs(
		Humanoid:GetChildren()
	) do
		if
			Object:IsA("NumberValue")
			and Object.Name:match(
				"Scale$"
			)
		then
			Result[Object.Name] =
				Object.Value
		end
	end

	local KnownNames = {
		"BodyHeightScale",
		"BodyWidthScale",
		"BodyDepthScale",
		"HeadScale",
		"BodyTypeScale",
		"BodyProportionScale"
	}

	for _, Name in ipairs(
		KnownNames
	) do
		if Result[Name] == nil then
			local Value =
				Humanoid:FindFirstChild(
					Name
				)

			if
				Value
				and Value:IsA(
					"NumberValue"
				)
			then
				Result[Name] =
					Value.Value
			end
		end
	end

	return Result
end

local function CalculateBodyBounds(
	Character
)
	local Root =
		Character:FindFirstChild(
			"HumanoidRootPart"
		)

	if
		not Root
		or not Root:IsA("BasePart")
	then
		return nil
	end

	local MinX = math.huge
	local MinY = math.huge
	local MinZ = math.huge

	local MaxX = -math.huge
	local MaxY = -math.huge
	local MaxZ = -math.huge

	local Found = false

	for _, Part in ipairs(
		Character:GetChildren()
	) do
		if
			Part:IsA("BasePart")
			and Part ~= Root
		then
			local Definition =
				GetPartDefinition(
					Part.Name
				)

			if Definition then
				local Half =
					Part.Size * 0.5

				for X = -1, 1, 2 do
					for Y = -1, 1, 2 do
						for Z = -1, 1, 2 do
							local WorldPoint =
								Part.CFrame
								* Vector3.new(
									Half.X * X,
									Half.Y * Y,
									Half.Z * Z
								)

							local LocalPoint =
								Root.CFrame:
									PointToObjectSpace(
										WorldPoint
									)

							MinX =
								math.min(
									MinX,
									LocalPoint.X
								)

							MinY =
								math.min(
									MinY,
									LocalPoint.Y
								)

							MinZ =
								math.min(
									MinZ,
									LocalPoint.Z
								)

							MaxX =
								math.max(
									MaxX,
									LocalPoint.X
								)

							MaxY =
								math.max(
									MaxY,
									LocalPoint.Y
								)

							MaxZ =
								math.max(
									MaxZ,
									LocalPoint.Z
								)

							Found = true
						end
					end
				end
			end
		end
	end

	if not Found then
		return nil
	end

	local Size =
		Vector3.new(
			MaxX - MinX,
			MaxY - MinY,
			MaxZ - MinZ
		)

	local Center =
		Vector3.new(
			(MinX + MaxX) * 0.5,
			(MinY + MaxY) * 0.5,
			(MinZ + MaxZ) * 0.5
		)

	return {
		width =
			Size.X,

		height =
			Size.Y,

		depth =
			Size.Z,

		size =
			VectorToTable(
				Size
			),

		centerOffset =
			VectorToTable(
				Center
			),

		min =
			{
				MinX,
				MinY,
				MinZ
			},

		max =
			{
				MaxX,
				MaxY,
				MaxZ
			}
	}
end

local function CalculateFullBounds(
	Character
)
	local Success, BoxCFrame, BoxSize =
		pcall(function()
			local CFrameValue,
				SizeValue =
				Character:GetBoundingBox()

			return
				CFrameValue,
				SizeValue
		end)

	if
		not Success
		or typeof(BoxCFrame)
			~= "CFrame"
		or typeof(BoxSize)
			~= "Vector3"
	then
		return nil
	end

	return {
		width =
			BoxSize.X,

		height =
			BoxSize.Y,

		depth =
			BoxSize.Z,

		size =
			VectorToTable(
				BoxSize
			),

		cframe =
			CFrameToTable(
				BoxCFrame
			)
	}
end

local function ExtractSizeProfile(
	Character,
	Humanoid
)
	local Profile = {
		rigType =
			Humanoid.RigType.Name,

		scales =
			ExtractScaleValues(
				Humanoid
			),

		hipHeight =
			Humanoid.HipHeight,

		bodyBounds =
			CalculateBodyBounds(
				Character
			),

		fullCharacterBounds =
			CalculateFullBounds(
				Character
			)
	}

	local AutomaticScalingEnabled =
		GetProperty(
			Humanoid,
			"AutomaticScalingEnabled"
		)

	if AutomaticScalingEnabled ~= nil then
		Profile.automaticScalingEnabled =
			AutomaticScalingEnabled
	end

	local Root =
		Character:FindFirstChild(
			"HumanoidRootPart"
		)

	if
		Root
		and Root:IsA("BasePart")
	then
		Profile.rootPartSize =
			VectorToTable(
				Root.Size
			)
	end

	local ModelScale

	local Success =
		pcall(function()
			ModelScale =
				Character:GetScale()
		end)

	if
		Success
		and type(ModelScale)
			== "number"
	then
		Profile.modelScale =
			ModelScale
	end

	local Scales =
		Profile.scales

	Profile.heightScale =
		Scales.BodyHeightScale

	Profile.widthScale =
		Scales.BodyWidthScale

	Profile.depthScale =
		Scales.BodyDepthScale

	Profile.headScale =
		Scales.HeadScale

	Profile.bodyTypeScale =
		Scales.BodyTypeScale

	Profile.bodyProportionScale =
		Scales.BodyProportionScale

	return Profile
end

local function ExtractHumanoid(
	Humanoid
)
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
			Humanoid.DisplayName,

		scales =
			ExtractScaleValues(
				Humanoid
			)
	}
end

local function ExtractCharacter()
	local Character =
		Player.Character

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
		version =
			4,

		source =
			"character",

		sourceRig =
			Humanoid.RigType.Name,

		name =
			Character.Name,

		sizeProfile =
			ExtractSizeProfile(
				Character,
				Humanoid
			),

		bodyMap =
			ExtractBodyMap(
				Character,
				Humanoid
			),

		bodyParts = {},

		characterMeshes =
			ExtractCharacterMeshes(
				Character
			),

		joints =
			ExtractJointMap(
				Character
			),

		accessories = {},

		clothing =
			ExtractClothing(
				Character
			),

		bodyColors =
			ExtractBodyColors(
				Character
			),

		decals =
			ExtractDecals(
				Character
			),

		animations =
			ExtractAnimations(
				Character
			),

		playingAnimations =
			ExtractPlayingAnimations(
				Humanoid
			),

		humanoid =
			ExtractHumanoid(
				Humanoid
			)
	}

	for _, Object in ipairs(
		Character:GetChildren()
	) do
		if Object:IsA("BasePart") then
			table.insert(
				Avatar.bodyParts,
				{
					type =
						"actualBodyPart",

					data =
						EncodeJSON(
							ExtractBodyPart(
								Object
							)
						)
				}
			)

		elseif Object:IsA("Accessory") then
			table.insert(
				Avatar.accessories,
				{
					type =
						"actualAccessory",

					data =
						EncodeJSON(
							ExtractAccessory(
								Object
							)
						)
				}
			)
		end
	end

	return HttpService:JSONEncode(
		{
			selected =
				"Extracted",

			avatars = {
				Extracted =
					Avatar
			}
		}
	)
end

local PlayerGui =
	Player:WaitForChild(
		"PlayerGui"
	)

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
	Instance.new(
		"ScreenGui"
	)

Gui.Name =
	"AvatarExtractor"

Gui.ResetOnSpawn =
	false

Gui.IgnoreGuiInset =
	true

pcall(function()
	Gui.Parent =
		CoreGui
end)

if not Gui.Parent then
	Gui.Parent =
		PlayerGui
end

local Container =
	Instance.new(
		"Frame"
	)

Container.Name =
	"Container"

Container.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

Container.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)

Container.Size =
	UDim2.fromOffset(
		720,
		470
	)

Container.BackgroundTransparency =
	1

Container.Parent =
	Gui

local TextBox =
	Instance.new(
		"TextBox"
	)

TextBox.Name =
	"Output"

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

TextBox.BorderSizePixel =
	0

TextBox.ClearTextOnFocus =
	false

TextBox.MultiLine =
	true

TextBox.TextWrapped =
	false

TextBox.TextXAlignment =
	Enum.TextXAlignment.Left

TextBox.TextYAlignment =
	Enum.TextYAlignment.Top

TextBox.Font =
	Enum.Font.Code

TextBox.TextSize =
	15

TextBox.Parent =
	Container

local TextCorner =
	Instance.new(
		"UICorner"
	)

TextCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

TextCorner.Parent =
	TextBox

local Padding =
	Instance.new(
		"UIPadding"
	)

Padding.PaddingTop =
	UDim.new(
		0,
		12
	)

Padding.PaddingBottom =
	UDim.new(
		0,
		12
	)

Padding.PaddingLeft =
	UDim.new(
		0,
		12
	)

Padding.PaddingRight =
	UDim.new(
		0,
		12
	)

Padding.Parent =
	TextBox

local Refresh =
	Instance.new(
		"TextButton"
	)

Refresh.Name =
	"Refresh"

Refresh.AnchorPoint =
	Vector2.new(
		0.5,
		1
	)

Refresh.Position =
	UDim2.new(
		0.5,
		0,
		1,
		0
	)

Refresh.Size =
	UDim2.fromOffset(
		150,
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

Refresh.BorderSizePixel =
	0

Refresh.Font =
	Enum.Font.GothamMedium

Refresh.TextSize =
	14

Refresh.Text =
	"Refresh"

Refresh.Parent =
	Container

local RefreshCorner =
	Instance.new(
		"UICorner"
	)

RefreshCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

RefreshCorner.Parent =
	Refresh

local function RefreshOutput()
	TextBox.Text =
		ExtractCharacter()

	TextBox.CursorPosition =
		#TextBox.Text + 1
end

Refresh.MouseButton1Click:Connect(
	function()
		Refresh.Text =
			"Refreshing..."

		task.wait()

		RefreshOutput()

		Refresh.Text =
			"Refresh"
	end
)

Player.CharacterAdded:Connect(
	function(Character)
		Character:WaitForChild(
			"Humanoid"
		)

		task.wait(
			0.75
		)

		RefreshOutput()
	end
)

RefreshOutput()
