AddCSLuaFile()

local ammoCvar = CreateConVar("ttt_car_gun_ammo", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How much ammo the car gun has", 1)

SWEP.PrintName = "Truck Gun"
SWEP.Spawnable = true
SWEP.Base = "weapon_tttbase"
SWEP.Slot = 6
SWEP.Kind = WEAPON_EQUIP1
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = false
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.AutoSpawnable = false
SWEP.HoldType = "pistol"
SWEP.Primary.Recoil = 3
SWEP.Primary.Damage = 1
SWEP.Primary.Delay = 1
SWEP.Primary.Cone = 0.01
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = ammoCvar:GetInt()
SWEP.Primary.DefaultClip = ammoCvar:GetInt()
SWEP.Primary.ClipMax = ammoCvar:GetInt()
SWEP.Primary.Ammo = "AirboatGun"
SWEP.AmmoEnt = "none"
SWEP.UseHands = true
SWEP.Weight = 7
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.ViewModelFlip = false
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Sound = Sound("ttt_car_gun/beepbeep.mp3")

SWEP.CanBuy = {ROLE_TRAITOR}

if CLIENT then
    SWEP.Icon = "vgui/ttt/weapon_ttt_car_gun.png"

    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Shoot a flying car at someone and freeze them in place!\n\nAnyone caught in the way of the car between you and the victim also takes damage."
    }
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
    self.Primary.ClipSize = ammoCvar:GetInt()
    self.Primary.DefaultClip = ammoCvar:GetInt()
    self.Primary.ClipMax = ammoCvar:GetInt()
end

function SWEP:PrimaryAttack()
    if CLIENT or not self:CanPrimaryAttack() then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    owner:EmitSound("weapons/pistol/pistol_fire2.wav")
    owner:EmitSound(self.Sound)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    local cone = self.Primary.Cone
    local bullet = {}
    bullet.Attacker = owner
    bullet.Num = 1
    bullet.Src = owner:GetShootPos()
    bullet.Dir = owner:GetAimVector()
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 1
    bullet.Force = 10
    bullet.Damage = 1
    bullet.AmmoType = self.Primary.Ammo
    bullet.TracerName = "PhyscannonImpact"
    local truck = ents.Create("prop_physics")
    truck:SetModel("models/ttt_pack_a_punch/semitruck/semitruck.mdl")
    truck:SetPos(owner:GetPos())
    -- truck:SetMaterial(TTT_PAP_CAMO)
    truck:SetMaterial("models/ttt_pack_a_punch/semitruck/semitruck")
    truck:Spawn()

    bullet.Callback = function(att, tr)
        if SERVER then end -- local victim = tr.Entity -- if IsValid(victim) then -- victim:EmitSound(self.Sound) -- if SERVER and victim:IsPlayer() then -- local victimAim = owner:GetAimVector() -- victimAim.x = -victimAim.x -- victimAim.y = -victimAim.y -- victimAim.z = -victimAim.z -- victimAim = victimAim:Angle() -- victim:SetEyeAngles(victimAim) -- timer.Simple(0, function() -- victim:Lock() -- car:SetPos(owner:EyePos() + owner:GetAimVector() * 100) -- car:SetAngles(owner:EyeAngles()) -- car:SetOwner(owner) -- car.SWEP = self -- car.Target = victim -- end) -- end -- end -- end
        owner:FireBullets(bullet)

        if SERVER then
            self:TakePrimaryAmmo(1)

            if self:Clip1() <= 0 then
                self:Remove()
            end
        end
    end
end

function SWEP:SecondaryAttack()
end

function SWEP:Holster()
    return true
end