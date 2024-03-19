SWEP.Base = "fg_laser_pistol"

local base_class = fg_base.SetupSWEP(SWEP, "Laser SMG")

SWEP.ViewModel = "models/weapons/c_smg1.mdl"

SWEP.WorldModel = "models/weapons/w_smg1.mdl"

SWEP.Primary.Ammo = "SMG1"

SWEP.Primary.ClipSize = 45

SWEP.Primary.DefaultClip = 45

SWEP.Primary.Automatic = true

SWEP.Primary.Damage = 80

SWEP.Primary.Spread = 0.2

SWEP.Primary.VerticalViewPunch = 2

SWEP.Primary.HorizontalViewPunch = { -1, 1 }

SWEP.PrimaryFireInterval = 0.1

SWEP.Secondary.Ammo = "SMG1"

SWEP.Secondary.Enabled = true

SWEP.SecondaryFireInterval = 3

SWEP.UsesSecondaryAmmo = true

SWEP.AttackSate = fg_base.ATTACK_STATE_FINISHED

function SWEP:PostInitialize()
	base_class.PostInitialize(self)

	self:SetHoldType("smg")

	self:SetAttackState(fg_base.ATTACK_STATE_FINISHED)
end

function SWEP:GetAttackState()
	return self.AttackSate
end

function SWEP:SetAttackState(state)
	self.AttackSate = tonumber(state) or fg_base.ATTACK_STATE_FINISHED
end

function SWEP:DoSecondaryAttack()
	if self:GetAttackState() ~= fg_base.ATTACK_STATE_FINISHED then return end

	self.Primary.Enabled = false
	self.Secondary.Enabled = false

	self:SetAttackState(fg_base.ATTACK_STATE_START)
end

function SWEP:DoBigAttack()
	if self:Clip1() <= 0 then
		self:SetAttackState(fg_base.ATTACK_STATE_FINISHED)

		self.Primary.Enabled = true
		self.Secondary.Enabled = true

		return
	end

	-- Spoof primary attack
	self.m_bInPrimaryAttack = true
		local vertical_view_punch = self.Primary.VerticalViewPunch -- Don't get too crazy
		local horizontal_view_punch = self.Primary.HorizontalViewPunch
		local damage = self.Primary.Damage -- Rekt

		self.Primary.VerticalViewPunch = 0.1
		self.Primary.HorizontalViewPunch = { -0.1, 0.1 }
		self.Primary.Damage = 100
			self:DoPrimaryAttack()
		self.Primary.Damage = damage
		self.Primary.HorizontalViewPunch = horizontal_view_punch
		self.Primary.VerticalViewPunch = vertical_view_punch
	self.m_bInPrimaryAttack = false

	self:SetNextThinkTime(CurTime() + 0.05)

	return true
end

function SWEP:OnThink()
	local attack_state = self:GetAttackState()

	local is_started = attack_state == fg_base.ATTACK_STATE_START
	local is_ongoing = attack_state == fg_base.ATTACK_STATE_ONGOING

	if is_started or is_ongoing then
		if is_started then
			self:SetAttackState(fg_base.ATTACK_STATE_ONGOING)
		end

		return self:DoBigAttack()
	end
end
