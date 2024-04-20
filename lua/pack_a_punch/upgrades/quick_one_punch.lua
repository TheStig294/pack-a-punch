local UPGRADE = {}
UPGRADE.id = "quick_one_punch"
UPGRADE.class = "one_punch_skin"
UPGRADE.name = "Quick One Punch!!!"
UPGRADE.desc = "x2 punch speed, shows the anime intro around you!"

function UPGRADE:Apply(SWEP)
    local own = SWEP:GetOwner()
    if not IsValid(own) then return end
    own:SetNWBool("PAPQuickOnePunch", true)
    local material = Material("ttt_pack_a_punch/quick_one_punch/intro")
    own:EmitSound("ttt_pack_a_punch/quick_one_punch/intro.mp3")
    own:SetMaterial(TTTPAP.camo)

    self:AddHook("PostDrawOpaqueRenderables", function()
        for _, ply in player.Iterator() do
            if ply:GetNWBool("PAPQuickOnePunch") and self:IsAlive(ply) then
                local angle = ply:EyeAngles()
                angle.x = 0
                cam.Start3D2D(ply:GetPos(), angle + Angle(0, 90, 90), 0.1)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(material)
                surface.DrawTexturedRect(-256, -1024, 1024, 1024)
                cam.End3D2D()
            end
        end
    end)

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        owner:SetAnimation(PLAYER_ATTACK1)
        local anim = "fists_left"
        local vm = owner:GetViewModel()
        vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))
        self:EmitSound("WeaponFrag.Throw")
        self:UpdateNextIdle()
        self:SetNextMeleeAttack(CurTime() + 0.1)
        self:SetNextPrimaryFire(CurTime() + 0.45)
    end

    self:AddToHook(SWEP, "Deploy", function()
        SWEP:StopSound("one_punch_left.wav")
        local owner = SWEP:GetOwner()

        if IsValid(owner) then
            owner:EmitSound("ttt_pack_a_punch/quick_one_punch/intro.mp3")
            owner:SetMaterial(TTTPAP.camo)
            owner:SetNWBool("PAPQuickOnePunch", true)
        end

        return true
    end)

    self:AddToHook(SWEP, "Holster", function()
        local owner = SWEP:GetOwner()

        if IsValid(owner) then
            owner:StopSound("ttt_pack_a_punch/quick_one_punch/intro.mp3")
            owner:SetMaterial("")
            owner:SetNWBool("PAPQuickOnePunch", false)
        end

        return true
    end)

    function SWEP:SecondaryAttack()
    end

    timer.Simple(0.1, function()
        own:StopSound("one_punch_left.wav")
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        ply:SetNWBool("PAPQuickOnePunch", false)
        ply:StopSound("ttt_pack_a_punch/quick_one_punch/intro.mp3")
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply:SetMaterial("")
        ply:SetNWBool("PAPQuickOnePunch", false)
    end
end

TTTPAP:Register(UPGRADE)