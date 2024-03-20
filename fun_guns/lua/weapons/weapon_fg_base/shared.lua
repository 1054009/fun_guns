AddCSLuaFile()

--[[
	Setup default values
]]

SWEP.Base = "weapon_base"
SWEP.PrintName = "Fun Gun Base"

SWEP.Category = "Fun Guns"

SWEP.Author = "afeokgegkwpok"
SWEP.Contact = "https://mn.gov/mnddc/parallels2/pdf/60s/63/63-AHG-NARC.pdf"

SWEP.UseHands = true

--[[
	Get our extensions
]]

include("sh_util.lua")
include("sh_ammo.lua")

AccessorFunc(SWEP, "m_iReloadAnimation", "ReloadAnimation", FORCE_NUMBER)

--[[
	Default ammo
]]

do
	local default_ammo = {
		-- Default values
		Ammo = "",
		ClipSize = -1,
		DefaultClip = 0,
		Automatic = false,

		-- Custom values
		ViewPunch = { 0, 0, 0, 0 }, 		-- How far view punch will go (up, down, left, right)
		AimPunch = { 0, 0, 0, 0 }, 			-- How far aim punch will go (up, down, left, right)
		BulletCount = 0, 					-- How many bullets to shoot
		BulletSpread = 0, 					-- Maximum x/y spread for bullets
		BulletDamage = 0, 					-- Base damage of a bullet
		BulletDistance = 56756, 			-- How far can a bullet travel
		FireInterval = 0, 					-- How many seconds in between shots
		UsesAmmo = true, 					-- Whether or not this fire type uses ammo
		Enabled = false, 					-- Whether or not we're allowed to attack like this
		Sound = "" 							-- The sound to make when this is fired
	}

	SWEP:SetupAmmo("Primary", default_ammo)
	SWEP:SetupAmmo("Secondary", default_ammo)
end

--[[
	Setup hooks
]]

function SWEP:OnInitialize()
	-- For override
end

function SWEP:Initialize()
	self:SetRandomSeed(self:GetRandomCRC())
	self:SetReloadAnimation(ACT_VM_RELOAD)

	hook.Add("PostEntityFireBullets", self, function(self, entity, bullet_data)
		if entity ~= self:GetOwner() then return end

		self:PostBulletFired(bullet_data)
	end)

	self:OnInitialize()
end

function SWEP:CanReload()
	if not IsFirstTimePredicted() then return false end

	-- For override
	return true
end

function SWEP:OnReload(default_success)
	-- For override
end

function SWEP:Reload()
	if not self:CanReload() then return end

	local success = self:DefaultReload(self:GetReloadAnimation())

	if success then
		self:TryOwner("SetAnimation", PLAYER_RELOAD)
	end

	self:OnReload(default_success)
end

function SWEP:PostBulletFired(bullet_data)
	-- For override
	-- Callback from PostEntityFireBullets
end

function SWEP:CanPrimaryAttack()
	if not IsFirstTimePredicted() then return false end
	if not self.Primary.Enabled then return false end

	if CurTime() < self:GetNextPrimaryFire() then
		return false
	end

	if self.Primary.UsesAmmo and (not self:HasAmmo() or self:Clip1() <= 0) then
		self:Reload()
		return false
	end

	return true
end

function SWEP:CanSecondaryAttack()
	if not IsFirstTimePredicted() then return false end
	if not self.Secondary.Enabled then return false end

	if CurTime() < self:GetNextSecondaryFire() then
		return false
	end

	local clip = self:Clip2()
	if self:GetPrimaryAmmoType() == self:GetSecondaryAmmoType() then
		clip = self:Clip1()
	end

	if self.Secondary.UsesAmmo and (not self:HasAmmo() or clip <= 0) then
		return false
	end

	return true
end

function SWEP:OnPrimaryAttack()
	-- For override
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetInPrimaryFire(true)
		if self:OnPrimaryAttack() ~= false then
			self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

			self:TryOwner("SetAnimation", PLAYER_ATTACK1)
		end
	self:SetInPrimaryFire(false)
end

function SWEP:OnSecondaryAttack()
	-- For override
end

function SWEP:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end

	self:SetInSecondaryFire(true)
		if self:OnSecondaryAttack() ~= false then
			self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

			self:TryOwner("SetAnimation", PLAYER_ATTACK1)
		end
	self:SetInSecondaryFire(false)
end

function SWEP:CalcViewModelView()
	self.ViewModelFOV = self:GetConVarNumber("viewmodel_fov", 62)
end
