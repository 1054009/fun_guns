SWEP.Base = "fg_laser_pistol"

local base_class = fg_base.SetupSWEP(SWEP, "Laser Shotgun")

SWEP.ViewModel = "models/weapons/c_shotgun.mdl"

SWEP.WorldModel = "models/weapons/w_shotgun.mdl"

SWEP.Primary.Ammo = "Buckshot"

SWEP.Primary.ClipSize = 6

SWEP.Primary.DefaultClip = 6

SWEP.Primary.BulletCount = 7

SWEP.Primary.Damage = 1234

SWEP.Primary.Spread = 0.2

SWEP.Primary.VerticalViewPunch = 12

SWEP.Primary.HorizontalViewPunch = 0

SWEP.PrimaryFireInterval = 1

SWEP.ReloadState = fg_base.RELOAD_STATE_FINISHED

function SWEP:PostInitialize()
	base_class.PostInitialize(self)

	self:SetHoldType("shotgun")

	self:SetReloadState(fg_base.RELOAD_STATE_FINISHED)
end

function SWEP:GetReloadState()
	return self.ReloadState
end

function SWEP:SetReloadState(state)
	self.ReloadState = tonumber(state) or fg_base.RELOAD_STATE_FINISHED
end

function SWEP:CanReload()
	return self:GetReloadState() == fg_base.RELOAD_STATE_FINISHED
end

function SWEP:Reload()
	if not IsFirstTimePredicted() then return end
	if not self:CanReload() then return end

	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:SetAnimation(PLAYER_RELOAD)
	end

	-- Don't send the reload animation for the viewmodel
	-- That will be fired in ProcessReload

	self:DoReload()
end

function SWEP:DoReload()
	if not self:HasAmmo() then return end -- All gone!
	if CurTime() < self:GetNextPrimaryFire() then return end

	if self:GetReserveAmmo(self:GetPrimaryAmmoType()) <= 0 then -- Out of reserve ammo
		return
	end

	self:StartReload()
end

function SWEP:StartReload()
	self:SetReloadState(fg_base.RELOAD_STATE_START)

	self:SetBodygroup(1, 0) -- Make the shell visible

	self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
	self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
end

function SWEP:ProcessReload()
	if self:GetReloadState() ~= fg_base.RELOAD_STATE_ONGOING then
		return
	end

	local owner = self:GetOwner()
	if not IsValid(owner) then
		return self:FinishReload()
	end

	if self:GetReserveAmmo(self:GetPrimaryAmmoType()) <= 0 or self:Clip1() >= self:GetMaxClip1() then
		return self:FinishReload()
	end

	if CurTime() < self:GetNextPrimaryFire() then return end

	self:TakeAmmo(-1, self:GetPrimaryAmmoType())

	self:SendWeaponAnim(ACT_VM_RELOAD)

	self:SetNextThinkTime(CurTime() + self:SequenceDuration())

	return true
end

function SWEP:FinishReload()
	if self:GetReloadState() ~= fg_base.RELOAD_STATE_ONGOING then
		return
	end

	self:SetReloadState(fg_base.RELOAD_STATE_FINISHED)

	self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
	self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
end

function SWEP:OnThink()
	local reload_state = self:GetReloadState()

	local is_started = reload_state == fg_base.RELOAD_STATE_START
	local is_ongoing = reload_state == fg_base.RELOAD_STATE_ONGOING

	if is_started or is_ongoing then
		if is_started then
			self:SetReloadState(fg_base.RELOAD_STATE_ONGOING)
		end

		return self:ProcessReload()
	end
end
