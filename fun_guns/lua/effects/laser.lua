EFFECT.Material = Material("effects/tool_tracer")

function EFFECT:Init(effect_data)
	self.StartPos = self:GetTracerShootPos(effect_data:GetStart(), effect_data:GetEntity(), effect_data:GetAttachment())
	self.EndPos = effect_data:GetOrigin()

	self.Normal = Vector(self.StartPos)
	self.Normal:Sub(self.EndPos)

	self.NormalLength = self.Normal:Length() / 128

	self.Life = 0

	self.Color = Color(255, 255, 255, 255)

	self:SetRenderBoundsWS(self.StartPos, self.EndPos)
end

function EFFECT:Think()
	self.Life = self.Life + (FrameTime() * 4)
	return self.Life < 1
end

function EFFECT:Render()
	render.SetMaterial(self.Material)

	local life_normal = self.Normal * self.Life

	local start_pos = self.StartPos
	local end_pos = self.EndPos
	local sub_start_pos = self.StartPos - life_normal

	local start_coordinate = math.Rand(0, 1)
	local end_coordinate = start_coordinate + (life_normal:Length() / 128)

	for _ = 1, 3 do
		render.DrawBeam(sub_start_pos, end_pos, 8, start_coordinate, end_coordinate, self.Color)
	end

	end_coordinate = start_coordinate + self.NormalLength

	self.Color.a = 128 * (1 - self.Life)
		render.DrawBeam(start_pos, end_pos, 8, start_coordinate, end_coordinate, self.Color)
	self.Color.a = 255
end
