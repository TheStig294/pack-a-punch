local UPGRADE = {}
UPGRADE.id = "potion_leaping"
UPGRADE.class = "weapon_ttt_mc_speedpotion"
UPGRADE.name = "Leaping Potion"
UPGRADE.desc = "Jump much higher, no fall damage!"

UPGRADE.convars = {
    {
        name = "pap_potion_leaping_mult",
        type = "int"
    }
}

local multCvar = CreateConVar("pap_potion_leaping_mult", "5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Jump multiplier", 1, 10)

function UPGRADE:Apply(SWEP)
    local Enabled = false
    local HealSound1 = "minecraft_original/speed_end.wav"
    local HealSound3 = "minecraft_original/speed_attack.wav"
    local HealSound4 = "minecraft_original/glass1.wav"
    local DenySound = "minecraft_original/wood_click.wav"
    local DestroySound = "minecraft_original/glass2.wav"
    local mc_speed_push_cost = GetConVar("ttt_mc_speed_push_cost")

    function SWEP:SpeedEnable()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if not owner.PAPLeapingPotionOGJump then
            owner.PAPLeapingPotionOGJump = owner:GetJumpPower()
        end

        owner:SetJumpPower(owner.PAPLeapingPotionOGJump * multCvar:GetInt())
        owner.PAPLeappingPotion = true
        local timername = "use_ammo" .. self:EntIndex()

        timer.Create(timername, 0.1, 0, function()
            if not IsValid(self) then
                timer.Remove(timername)

                return
            end

            if self:Clip1() <= self.MaxAmmo then
                self:SetClip1(math.min(self:Clip1() - 1, self.MaxAmmo))
            end

            if self:Clip1() <= 0 then
                self:SpeedDisable()

                if SERVER then
                    self:Remove()
                end

                self:EmitSound(DestroySound)
            end
        end)

        Enabled = true
    end

    function SWEP:SpeedDisable()
        -- Only play the sound if we're enabled, but run everything else
        -- so we're VERY SURE this disables
        if Enabled then
            self:EmitSound(HealSound1)
        end

        local owner = self:GetOwner()

        if IsValid(owner) then
            -- 200 is the default jump height
            owner:SetJumpPower(owner.PAPLeapingPotionOGJump or 200)
            owner.PAPLeappingPotion = false
        end

        timer.Remove("use_ammo" .. self:EntIndex())
        Enabled = false
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if ent.PAPLeappingPotion and dmg:IsFallDamage() then return true end
    end)

    function SWEP:SecondaryAttack()
        if Enabled then
            self:SpeedDisable()
        else
            self:SpeedEnable()
        end
    end

    function SWEP:PreDrop()
        self.BaseClass.PreDrop(self)
        timer.Remove("use_ammo" .. self:EntIndex())

        if Enabled then
            self:SpeedDisable()
        end
    end

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if owner:IsPlayer() then
            owner:LagCompensation(true)
        end

        local tr = util.TraceLine({
            start = owner:GetShootPos(),
            endpos = owner:GetShootPos() + owner:GetAimVector() * 64,
            filter = owner
        })

        local ent = tr.Entity

        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
            self:EmitSound(HealSound4)
            ent:EmitSound(HealSound3)
            ent:SetGroundEntity(nil)
            ent:SetVelocity(Vector(0, 0, 1000))
            local pushCost = mc_speed_push_cost:GetInt()
            self:TakePrimaryAmmo(pushCost)
        else
            self:EmitSound(DenySound)
        end

        if self:Clip1() <= 0 then
            self:Remove()
            self:EmitSound(DestroySound)
        end
    end

    if CLIENT then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            SWEP:PAPOldDrawWorldModel()

            if IsValid(self.WorldModelEnt) then
                self.WorldModelEnt:SetMaterial(TTTPAP.camo)
            end
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPLeapingPotionOGJump = nil
    end
end

TTTPAP:Register(UPGRADE)