local UPGRADE = {}
UPGRADE.id = "potion_strength"
UPGRADE.class = "weapon_ttt_mc_speedpotion"
UPGRADE.name = "Strength Potion"
UPGRADE.desc = "Increases your damage, if used on someone else it lasts longer!"

UPGRADE.convars = {
    {
        name = "pap_potion_strength_mult",
        type = "float"
    },
    {
        name = "pap_potion_strength_other_player_cost",
        type = "int"
    },
    {
        name = "pap_potion_strength_other_player_secs",
        type = "int"
    }
}

local multCvar = CreateConVar("pap_potion_strength_mult", "1.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage multiplier", 1, 3)

local otherPlayerCostCvar = CreateConVar("pap_potion_strength_other_player_cost", "25", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Cost on using on other player", 1, 100)

local otherPlayerSecsCvar = CreateConVar("pap_potion_strength_other_player_time", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs other player dmg buff lasts", 1, 60)

function UPGRADE:Apply(SWEP)
    local HealSound1 = "minecraft_original/speed_end.wav"
    local HealSound2 = "minecraft_original/speed_start.wav"
    local DenySound = "minecraft_original/wood_click.wav"
    local DestroySound = "minecraft_original/glass2.wav"

    timer.Simple(0.1, function()
        SWEP.MaxAmmo = SWEP:Clip1()
    end)

    function SWEP:SpeedEnable()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner.PAPStrengthPotion = true
        self:EmitSound(HealSound2)
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

        self.PotionEnabled = true
    end

    function SWEP:SpeedDisable()
        -- Only play the sound if we're enabled, but run everything else
        -- so we're VERY SURE this disables
        if self.PotionEnabled then
            self:EmitSound(HealSound1)
        end

        local owner = self:GetOwner()

        if IsValid(owner) then
            owner.PAPStrengthPotion = false
        end

        timer.Remove("use_ammo" .. self:EntIndex())
        self.PotionEnabled = false
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        local attacker = dmg:GetAttacker()

        if self:IsAlivePlayer(attacker) and attacker.PAPStrengthPotion then
            dmg:ScaleDamage(multCvar:GetFloat())
        end
    end)

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
            self:EmitSound(HealSound2)
            ent:EmitSound(HealSound2)
            ent.PAPStrengthPotion = true
            ent:PrintMessage(HUD_PRINTCENTER, "Strength potion! Damage increased!")
            ent:PrintMessage(HUD_PRINTTALK, "Strength potion! You deal x" .. multCvar:GetFloat() .. " more damage for " .. otherPlayerSecsCvar:GetInt() .. " seconds")

            timer.Create("TTTPAPStrengthPotionOtherPlayerTimer" .. ent:SteamID64(), otherPlayerSecsCvar:GetInt(), 1, function()
                if IsValid(ent) then
                    ent.PAPStrengthPotion = false
                    ent:EmitSound(DenySound)
                end
            end)

            local pushCost = otherPlayerCostCvar:GetInt()
            self:TakePrimaryAmmo(pushCost)
        else
            self:EmitSound(DenySound)
        end

        if self:Clip1() <= 0 then
            self:Remove()
            self:EmitSound(DestroySound)
        end
    end

    self:AddHook("PostPlayerDeath", function(ply)
        ply.PAPStrengthPotion = nil
        timer.Remove("TTTPAPStrengthPotionOtherPlayerTimer" .. ply:SteamID64())
    end)

    if CLIENT then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            SWEP:PAPOldDrawWorldModel()

            if IsValid(self.WorldModelEnt) then
                self.WorldModelEnt:SetPAPCamo()
            end
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPStrengthPotion = nil
        timer.Remove("TTTPAPStrengthPotionOtherPlayerTimer" .. ply:SteamID64())
    end
end

TTTPAP:Register(UPGRADE)