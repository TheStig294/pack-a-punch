AddCSLuaFile()

if CLIENT then
    SWEP.PrintName = "Groovitron"
    SWEP.Slot = 3
    SWEP.Icon = "vgui/ttt/icon_nades"
end

SWEP.Base = "weapon_tttbasegrenade"
SWEP.HoldType = "grenade"
SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 72
SWEP.ViewModel = Model("models/ttt_pack_a_punch/disco_ball/disco_ball.mdl")
SWEP.WorldModel = Model("models/ttt_pack_a_punch/disco_ball/disco_ball.mdl")
SWEP.Kind = WEAPON_NADE
SWEP.AutoSpawnable = false
SWEP.AllowDrop = true
SWEP.NoSights = true
SWEP.detonate_timer = 3
SWEP.UseHands = false

function SWEP:Initialize()
    self:SetModelScale(10, 0.00001)

    return self.BaseClass.Initialize(self)
end

function SWEP:GetGrenadeName()
    return "ttt_pap_groovitron_proj"
end

if CLIENT then
    SWEP.EquipMenuData = {
        type = "Grenade",
        desc = "Forces players nearby to dance!"
    }

    -- Adjust these variables to move the viewmodel's position
    SWEP.IronSightsPos = Vector(2, 3, -2)
    SWEP.IronSightsAng = Vector(0, 0, 0)

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
            local offsetVec = Vector(10, 0, 0)
            local offsetAng = Angle(180, 0, 0)
            local boneid = Owner:LookupBone("ValveBiped.Bip01_R_Hand")
            if not boneid then return end
            local matrix = Owner:GetBoneMatrix(boneid)
            if not matrix then return end
            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
            WorldModel:SetPos(newPos)
            WorldModel:SetAngles(newAng)
            WorldModel:SetModelScale(10)
            WorldModel:SetupBones()
        else
            WorldModel:SetPos(self:GetPos())
            WorldModel:SetAngles(self:GetAngles())
        end

        WorldModel:DrawModel()
    end
end