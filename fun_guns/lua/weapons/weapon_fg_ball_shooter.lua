SWEP.Base = "weapon_fg_base"
SWEP.PrintName = "Ball Shooter"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Category = "Fun Guns"
SWEP.Slot = 6

SWEP.ViewModel = "models/weapons/c_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"

include("weapon_fg_base/sh_ammo.lua")

SWEP:SetupAmmo("Primary",
{
	Ammo = "Buckshot",
	ClipSize = 5,
	DefaultClip = 5,

	BulletCount = 5, -- How many balls to spawn
	UsesAmmo = true,
	Enabled = true
})

function SWEP:OnPrimaryAttack()
	local sent_ball = scripted_ents.GetStored("sent_ball")
	if not istable(sent_ball) then return false end -- Balls don't exist!

	local spawn_function = scripted_ents.GetMember("sent_ball", "SpawnFunction")
	if not isfunction(spawn_function) then return false end -- Balls can't be spawned properly

	local owner, is_player = self:TryOwner("IsPlayer")
	if not owner or not is_player then return false end -- Only players can make balls!

	if SERVER then
		local max_velocity = self:GetConVarNumber("sv_maxvelocity", 3500)

		local bullet_data = {}

		for bullet_index = 1, self:GetCurrentFireTable().BulletCount do
			self:GenerateBullet(bullet_data, bullet_index)

			local start_pos = bullet_data.Src
			local end_pos = bullet_data.Dir

			end_pos:Mul(owner:BoundingRadius() * 5) -- It doesn't matter if we modify this vector
			end_pos:Add(start_pos)

			local tr = self:RunTrace(start_pos, end_pos)
			tr.Hit = true -- Force the ball to spawn in front of us rather than on the ground

			local ball = spawn_function(sent_ball, owner, tr, "sent_ball")

			if IsValid(ball) then
				ball:SetCreator(owner)

				local physics_object = ball:GetPhysicsObject()

				if IsValid(physics_object) then -- If this isn't valid then the gun will be pretty lame...
					local forward = tr.Normal

					forward:Mul(max_velocity)

					physics_object:SetVelocity(forward)
				end
			end
		end
	end

	self:TakePrimaryAmmo(1)
	self:ApplyNextFireTime()

	self:ApplyAimPunch()
	self:ApplyViewPunch()

	return true
end
