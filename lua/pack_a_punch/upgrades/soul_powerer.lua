local UPGRADE = {}
UPGRADE.id = "soul_powerer"
UPGRADE.class = "weapon_ttt_smg_soulbinding"
UPGRADE.name = "Soul Powerer"
UPGRADE.desc = "All Soulbound abilities are upgraded!"

function UPGRADE:Apply(SWEP)
    -- Make a backup of old ability functionality
    if not SOULBOUND.PAPOldAbilities then
        SOULBOUND.PAPOldAbilities = {}
        SOULBOUND.PAPOldAbilities = table.Copy(SOULBOUND.Abilities)
    end

    -- 
    -- Bee barrel
    -- 
    local ABILITY = SOULBOUND.Abilities["beebarrel"]
    ABILITY.Name = "Place Upgraded Bee Barrel"
    ABILITY.Description = "Place an upgraded bee barrel that will release invincible big bees when it explodes"
    ABILITY.Icon = "ttt_pack_a_punch/soul_powerer/beebarrel"

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundBeeBarrelUses", beebarrel_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundBeeBarrelNextUse", CurTime())

        hook.Add("EntityTakeDamage", "TTTSoulboundBeeBarrelDamage", function(target, dmginfo)
            -- Spawned bees are invincible
            if target.TTTPAPSoulboundBee then return true end
            if target:GetClass() ~= "prop_physics" then return end
            if dmginfo:GetDamage() < 1 then return end
            local model = target:GetModel()
            if model ~= "models/bee_drum/beedrum002_explosive.mdl" then return end
            local pos = target:GetPos()
            local isUpgradedBarrel = target:GetMaterial() == TTTPAP.camo

            timer.Create("TTTSoulboundBeeBarrelSpawn", 0.1, beebarrel_bees:GetInt(), function()
                local spos = pos + Vector(math.random(-50, 50), math.random(-50, 50), math.random(0, 100))
                local headBee = ents.Create("npc_manhack")
                headBee:SetPos(spos)
                headBee:Spawn()
                headBee:Activate()
                headBee:SetNPCState(NPC_STATE_ALERT)

                if scripted_ents.Get("ttt_beenade_proj") ~= nil then
                    local bee = ents.Create("prop_dynamic")
                    bee:SetModel("models/lucian/props/stupid_bee.mdl")
                    bee:SetPos(spos)
                    bee:SetParent(headBee)
                    headBee:SetNoDraw(true)

                    if isUpgradedBarrel then
                        bee:SetModelScale(5, 0.0001)
                        bee:Activate()
                        bee:SetMaterial(TTTPAP.camo)
                        bee.TTTPAPSoulboundBee = true
                        headBee:SetModelScale(5, 0.0001)
                        headBee:Activate()
                        headBee.TTTPAPSoulboundBee = true
                    end
                end

                headBee:SetHealth(100000)
            end)
        end)
    end

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 48
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 15) + fwd
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/bee_drum/beedrum002_explosive.mdl")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:SetMaterial(TTTPAP.camo)
        local uses = soulbound:GetNWInt("TTTSoulboundBeeBarrelUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundBeeBarrelUses", uses)
        soulbound:SetNWFloat("TTTSoulboundBeeBarrelNextUse", CurTime() + beebarrel_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["beebarrel"] = ABILITY
end

function UPGRADE:Reset()
    -- Hopefully restore the Soulbound abilities to what they were
    -- (I've had problems with this in the past with the French randomat restoring old role names to English,
    -- but this is way less complicated than that so it will hopefully *just work*)
    if SOULBOUND.PAPOldAbilities then
        SOULBOUND.Abilities = table.Copy(SOULBOUND.PAPOldAbilities)
    end
end

TTTPAP:Register(UPGRADE)