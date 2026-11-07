local UPGRADE = {}
UPGRADE.id = "mobile_button"
UPGRADE.class = "weapon_btn_transformer"
UPGRADE.name = "Mobile Button"
UPGRADE.desc = "You can move while transformed!"

function UPGRADE:Apply(SWEP)
    -- Helper function to apply the upgrade regardless if the player is transformed already or not
    local function SetupMobileButton()
        local owner = SWEP:GetOwner()
        local button = SWEP.Button
        if not IsValid(owner) or not IsValid(button) then return end
        if owner.TTTPAPMobileButtonHeight then return end
        local height = button:GetHeight()

        -- If already transformed we need to stop the player from spectating the button
        if SERVER then
            owner:SpectateEntity(NULL)
            owner:UnSpectate()
        end

        owner:SetParent(NULL)
        -- The player is invisible, the button prop/entity follows them
        owner:SetNoDraw(true)
        self:SetUpgraded(button)
        button:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
        owner.TTTPAPMobileButtonHeight = height
        owner:SetPos(owner:GetPos() - Vector(0, 0, height))

        if SERVER then
            SYNC:SetEntityProperty(SWEP, "Button", button)
        end

        button:CallOnRemove("TTTPAPMobileButtonOnRemove", function()
            timer.Simple(0, function()
                if IsValid(owner) then
                    owner.TTTPAPMobileButtonHeight = nil
                    owner:SetNoDraw(false)
                end
            end)
        end)
    end

    self:AddToHook(SWEP, "PrimaryAttack", SetupMobileButton)

    -- Handle upgrading while already transformed
    if IsValid(SWEP.Button) then
        SetupMobileButton()
    end

    function SWEP:Think()
        local button = self.Button
        if not IsValid(button) then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        -- Only reposition the button when mobile mode is active
        if not owner.TTTPAPMobileButtonHeight then return end
        button:SetPos(owner:GetPos() + Vector(0, 0, owner.TTTPAPMobileButtonHeight))
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
        if not IsValid(owner) then return end
        if not owner.TTTPAPMobileButtonHeight then return end
        if IsValid(SWEP.Button) then return end
        owner:SetPos(owner:GetPos() + Vector(0, 0, owner.TTTPAPMobileButtonHeight))
        owner.TTTPAPMobileButtonHeight = nil
        owner:SetNoDraw(false)
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        local height = ply.TTTPAPMobileButtonHeight
        if not height then continue end
        local wep = ply:GetWeapon(UPGRADE.class)

        if IsValid(wep) and IsValid(wep.Button) then
            local button = wep.Button

            if SERVER then
                ply:SpectateEntity(NULL)
                ply:UnSpectate()

                if IsValid(button) then
                    button:Remove()
                end
            end

            ply:SetParent(NULL)
            ply:SetPos(ply:GetPos() + Vector(0, 0, height))
            wep.Button = nil
            wep.TransformBackTime = nil
        end

        ply.TTTPAPMobileButtonHeight = nil
        ply:SetNoDraw(false)
    end
end

TTTPAP:Register(UPGRADE)