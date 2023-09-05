AddCSLuaFile()
SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "Pokeball"
    SWEP.Slot = 6
    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false
    SWEP.Icon = ""
end

SWEP.Base = "weapon_tttbase"
SWEP.Primary.Ammo = "AirboatGun"
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.Delay = 1.0
SWEP.Primary.Cone = 0.01
SWEP.Primary.ClipSize = -1
SWEP.Primary.Automatic = false
SWEP.Primary.DefaultClip = -1
SWEP.Primary.ClipMax = -1
SWEP.Kind = WEAPON_EQUIP
SWEP.UseHands = true
SWEP.ViewModel = Model("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
SWEP.WorldModel = Model("models/ttt_pack_a_punch/pokeball/pokeball.mdl")

function SWEP:PrimaryAttack()
    if CLIENT then return end
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local TraceResult = owner:GetEyeTrace()
    local pokeball = ents.Create("ttt_pap_pokeball")
    pokeball:SetPos(TraceResult.HitPos + Vector(0, 0, 10))
    pokeball:Spawn()
end

function SWEP:SecondaryAttack()
end

if CLIENT then
    -- Adjust these variables to move the viewmodel's position
    SWEP.IronSightsPos = Vector(25.49, 0, -30.371)
    SWEP.IronSightsAng = Vector(12, 65, -20.19)

    function SWEP:GetViewModelPosition(EyePos, EyeAng)
        local Mul = 1.0
        local Offset = self.IronSightsPos

        if self.IronSightsAng then
            EyeAng = EyeAng * 1
            EyeAng:RotateAroundAxis(EyeAng:Right(), self.IronSightsAng.x * Mul)
            EyeAng:RotateAroundAxis(EyeAng:Up(), self.IronSightsAng.y * Mul)
            EyeAng:RotateAroundAxis(EyeAng:Forward(), self.IronSightsAng.z * Mul)
        end

        local Right = EyeAng:Right()
        local Up = EyeAng:Up()
        local Forward = EyeAng:Forward()
        EyePos = EyePos + Offset.x * Right * Mul
        EyePos = EyePos + Offset.y * Forward * Mul
        EyePos = EyePos + Offset.z * Up * Mul

        return EyePos, EyeAng
    end

    local WorldModel = ClientsideModel(SWEP.WorldModel)
    -- Settings...
    WorldModel:SetSkin(1)
    WorldModel:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        local _Owner = self:GetOwner()

        if IsValid(_Owner) then
            -- Specify a good position
            local offsetVec = Vector(5, -2.7, -3.4)
            local offsetAng = Angle(180, -90, 0)
            local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
            if not boneid then return end
            local matrix = _Owner:GetBoneMatrix(boneid)
            if not matrix then return end
            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
            WorldModel:SetPos(newPos)
            WorldModel:SetAngles(newAng)
            WorldModel:SetupBones()
        else
            WorldModel:SetPos(self:GetPos())
            WorldModel:SetAngles(self:GetAngles())
        end

        WorldModel:DrawModel()
    end
end