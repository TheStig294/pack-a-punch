local UPGRADE = {}
UPGRADE.id = "no_take_backsies_potato"
UPGRADE.class = "weapon_ttt_hotpotato"
UPGRADE.name = "No Take Backsies Potato"
UPGRADE.desc = "Cannot be given back.\nImmune to the bigger explosion!"

function UPGRADE:Apply(SWEP)
    -- If this is not being passed to a player, and is the owner upgrading the weapon themselves, then set them as the owner
    if not IsValid(SWEP.PAPOriginalOwner) then
        SWEP.PAPOriginalOwner = SWEP:GetOwner()
    end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        local victim = owner:GetEyeTrace().Entity
        if not victim:IsPlayer() then return end
        if not IsValid(victim:GetActiveWeapon()) then return end
        if victim:GetActiveWeapon():GetClass() == self:GetClass() and victim:GetActiveWeapon().PotatoChef ~= nil then return end
        dist2 = owner:GetPos():DistToSqr(victim:GetPos())

        if dist2 < 10000 and SERVER then
            if not self.PotatoChef then
                self.PotatoChef = owner
            end

            hook.Add("TTTPrepareRound", owner:Name() .. "_RoundRestartCleanup", function()
                fn_CleanUpAll()
            end)

            if victim == SWEP.PAPOriginalOwner then
                attacker:PrintMessage(HUD_PRINTCENTER, "No take backsies! Find someone else!")

                return
            end

            self:PotatoTime(victim, self.PotatoChef)
            -- Upgrade the victim's potato so it still has all of the same upgrade effects
            local victimPotato = victim:GetWeapon(UPGRADE.class)

            if IsValid(victimPotato) then
                victimPotato.PAPOriginalOwner = self.PAPOriginalOwner
                self.PAPUpgrade.noDesc = true
                TTTPAP:ApplyUpgrade(victimPotato, self.PAPUpgrade)
            end

            owner:StripWeapon("weapon_ttt_hotpotato")

            for _, info in ipairs(self.StrippedTable) do
                owner:Give(info[1])
                local wep = owner:GetWeapon(info[1])
                wep:SetClip1(info[2])
                wep:SetClip2(info[3])
            end
        end
    end

    SWEP.PAPOldDetonate = SWEP.Detonate

    function SWEP:Detonate(ply)
        if IsValid(self.PAPOriginalOwner) then
            self.PAPOriginalOwner.PAPPotatoExplosionImmune = true
        end

        self:PAPOldDetonate(ply)
        self:EmitSound("ambient/explosions/explode_3.wav")
        -- Purposely create the explosion via an explosion entity, as this is how the hot potato does it,
        -- so the original owner is also immune to our additional explosion as well!
        local explode = ents.Create("env_explosion")
        explode:SetPos(self:GetPos())
        explode:SetOwner(self:GetOwner())
        explode:SetKeyValue("iMagnitude", 550)
        explode:SetKeyValue("iRadiusOverride", 550)
        explode:Spawn()
        explode:Fire("Explode", 0, 0)
        -- Leaves a bunch of fire on exploding
        local tr = util.QuickTrace(self:GetPos(), Vector(0, 0, -1))
        StartFires(self:GetPos(), tr, 20, 40, false, self:GetOwner())

        if IsValid(self.PAPOriginalOwner) then
            self.PAPOriginalOwner.PAPPotatoExplosionImmune = false
        end
    end

    -- The original owner of the upgraded hot potato is immune to the explosion
    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsPlayer(ply) or not ply.PAPPotatoExplosionImmune then return end
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) then return end
        if inflictor:GetClass() == "env_explosion" then return true end
    end)
end

TTTPAP:Register(UPGRADE)