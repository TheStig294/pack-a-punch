AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Jam"
    SWEP.Slot = 6
    SWEP.Icon = "vgui/ttt/icon_nades"
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "pistol"
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 72
SWEP.ViewModel = Model("models/ttt_pack_a_punch/jam/jam.mdl")
SWEP.WorldModel = Model("models/ttt_pack_a_punch/jam/jam.mdl")
SWEP.Kind = WEAPON_EQUIP
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.NoSights = true
SWEP.UseHands = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1

function SWEP:PrimaryAttack()
end

if CLIENT then
    SWEP.EquipMenuData = {
        type = "Joke Weapon",
        desc = "A jar of jam. Doesn't do anything..."
    }

    -- Adjust these variables to move the viewmodel's position
    SWEP.IronSightsPos = Vector(-10, -20, -8)
    SWEP.IronSightsAng = Vector(0, 180, 0)

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
    WorldModel:SetSkin(1)
    WorldModel:SetNoDraw(true)

    function SWEP:DrawWorldModel()
        local Owner = self:GetOwner()

        if IsValid(Owner) then
            local offsetVec = Vector(5, -3, 0)
            local offsetAng = Angle(180, 0, 0)
            local boneid = Owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end
            local matrix = Owner:GetBoneMatrix(boneid)
            if not matrix then return end
            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
            WorldModel:SetPos(newPos)
            WorldModel:SetAngles(newAng)
            WorldModel:SetupBones()
        else
            WorldModel:SetPos(self:GetPos())
            WorldModel:SetAngles(self:GetAngles())
        end

        if self.PAPUpgrade then
            WorldModel:SetPAPCamo()
        else
            WorldModel:SetMaterial("")
        end

        WorldModel:DrawModel()
    end
end