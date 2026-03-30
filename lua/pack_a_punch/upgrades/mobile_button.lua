local UPGRADE = {}
UPGRADE.id = "mobile_button"
UPGRADE.class = "weapon_btn_transformer"
UPGRADE.name = "Mobile Button"
UPGRADE.desc = "You can move while transformed!"

function UPGRADE:Apply(SWEP)
    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if CLIENT or not IsValid(SWEP.Button) or not IsValid(owner) or owner.TTTPAPMobileButtonHeight then return end

        if SERVER then
            owner:SpectateEntity(nil)
            owner:UnSpectate()
        end

        owner:SetParent(nil)
        local button = SWEP.Button
        if not IsValid(button) then return end
        self:SetUpgraded(button)
        button:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
        owner.TTTPAPMobileButtonHeight = button:GetHeight()
        owner:SetPos(owner:GetPos() - Vector(0, 0, owner.TTTPAPMobileButtonHeight))
        SYNC:SetEntityProperty(SWEP, "Button", button)

        button:CallOnRemove("TTTPAPMobileButtonOnRemove", function()
            timer.Simple(0, function()
                if IsValid(owner) then
                    owner.TTTPAPMobileButtonHeight = nil
                end
            end)
        end)
    end)

    function SWEP:Think()
        local button = self.Button
        if not IsValid(button) then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        button:SetPos(owner:GetPos() + Vector(0, 0, button:GetHeight()))
        local angles = owner:EyeAngles()
        angles.x = 0
        button:SetAngles(angles)
        self:NextThink(CurTime())

        if CLIENT then
            self:SetNextClientThink(CurTime())
        end

        return true
    end

    self:AddToHook(SWEP, "SecondaryAttack", function()
        local owner = SWEP:GetOwner()
        if CLIENT or IsValid(SWEP.Button) or not IsValid(owner) or not owner.TTTPAPMobileButtonHeight then return end
        owner:SetPos(owner:GetPos() + Vector(0, 0, owner.TTTPAPMobileButtonHeight))
        owner.TTTPAPMobileButtonHeight = nil
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPMobileButtonHeight = nil
    end
end

TTTPAP:Register(UPGRADE)