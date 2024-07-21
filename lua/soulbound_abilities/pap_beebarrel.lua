-- These abilities were created by by Nick, Spazz, and Mal for the Soulbound role
-- 
-- This is all their code except for the changes I made to upgrade the abilities
local ABILITY = {}
ABILITY.Name = "Place Upgraded Bee Barrel"
ABILITY.Id = "pap_beebarrel"
ABILITY.Description = "Place an upgraded bee barrel that will release invincible big bees when it explodes"
ABILITY.Icon = "vgui/ttt/roles/sbd/abilities/icon_pap_beebarrel.png"
local pap_beebarrel_uses = CreateConVar("ttt_soulbound_pap_beebarrel_uses", "3", FCVAR_REPLICATED, "How many uses of the place bee barrel ability should the Soulbound get. (Set to 0 for unlimited uses)", 0, 10)
local pap_beebarrel_bees = CreateConVar("ttt_soulbound_pap_beebarrel_bees", "3", FCVAR_REPLICATED, "How many bees per beebarrel", 1, 10)
local pap_beebarrel_cooldown = CreateConVar("ttt_soulbound_pap_beebarrel_cooldown", "0", FCVAR_NONE, "How long should the Soulbound have to wait between uses of the place bee barrel ability", 0, 10)

table.insert(ROLE_CONVARS[ROLE_SOULBOUND], {
    cvar = "ttt_soulbound_pap_beebarrel_uses",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

table.insert(ROLE_CONVARS[ROLE_SOULBOUND], {
    cvar = "ttt_soulbound_pap_beebarrel_cooldown",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 1
})

table.insert(ROLE_CONVARS[ROLE_SOULBOUND], {
    cvar = "ttt_soulbound_pap_beebarrel_bees",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

if SERVER then
    local function Pap_beebarrelDamage(target, dmginfo)
        if target:GetClass() ~= "prop_physics" then return end
        if dmginfo:GetDamage() < 1 then return end
        local model = target:GetModel()
        if model ~= "models/bee_drum/beedrum002_explosive.mdl" then return end
        local pos = target:GetPos()

        timer.Create("TTTSoulboundPap_beebarrelSpawn", 0.1, pap_beebarrel_bees:GetInt(), function()
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
                bee:SetMaterial(TTTPAP.camo)
                headBee:SetNoDraw(true)
            end

            headBee:SetHealth(10)
        end)
    end

    function ABILITY:Bought(soulbound)
        print("Upgraded Bought")

        if not soulbound:GetNWBool("TTTPAPSoulPowerer") then
            local OLD_ABILITY = SOULBOUND.PAPOldAbilities[string.sub(ABILITY.Id, 5)]
            OLD_ABILITY:Bought(soulbound)
            print("Old Bought")

            return
        end

        soulbound:SetNWInt("TTTSoulboundPap_beebarrelUses", pap_beebarrel_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundPap_beebarrelNextUse", CurTime())
        hook.Add("EntityTakeDamage", "TTTSoulboundPap_beebarrelDamage", Pap_beebarrelDamage)
    end

    function ABILITY:Condition(soulbound, target)
        print("Upgraded Condition")

        if not soulbound:GetNWBool("TTTPAPSoulPowerer") then
            print("Old Condition")
            local OLD_ABILITY = SOULBOUND.PAPOldAbilities[string.sub(ABILITY.Id, 5)]

            return OLD_ABILITY:Condition(soulbound)
        end

        if not soulbound:IsInWorld() then return false end
        if pap_beebarrel_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundPap_beebarrelUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundPap_beebarrelNextUse") then return false end

        return true
    end

    function ABILITY:Use(soulbound, target)
        print("Upgraded Use")

        if not soulbound:GetNWBool("TTTPAPSoulPowerer") then
            print("Old Use")
            local OLD_ABILITY = SOULBOUND.PAPOldAbilities[string.sub(ABILITY.Id, 5)]

            return OLD_ABILITY:Use(soulbound)
        end

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
        local uses = soulbound:GetNWInt("TTTSoulboundPap_beebarrelUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundPap_beebarrelUses", uses)
        soulbound:SetNWFloat("TTTSoulboundPap_beebarrelNextUse", CurTime() + pap_beebarrel_cooldown:GetFloat())
    end

    function ABILITY:Cleanup(soulbound)
        print("Upgraded Cleanup")
        local oldAbilityID = string.sub(ABILITY.Id, 5)
        print("Old ability ID:", oldAbilityID)
        PrintTable(SOULBOUND)
        local OLD_ABILITY = SOULBOUND.PAPOldAbilities[oldAbilityID]
        print(OLD_ABILITY)
        print(OLD_ABILITY.Cleanup)
        -- soulbound:SetNWInt("TTTSoulboundPap_beebarrelUses", 0)
        -- soulbound:SetNWFloat("TTTSoulboundPap_beebarrelNextUse", 0)

        return OLD_ABILITY:Cleanup(soulbound)
    end

    local enabled = GetConVar("ttt_soulbound_pap_beebarrel_enabled")

    hook.Add("TTTPrepareRound", "Soulbound_Pap_beebarrel_TTTPrepareRound", function()
        if enabled:GetBool() and not scripted_ents.Get("ttt_beenade_proj") then
            ErrorNoHalt("WARNING: Jenssen's BeeNade must be installed to enable the Soulbound's place bee barrel ability!\n")
            enabled:SetBool(false)
        end
    end)
end

if CLIENT then
    local ammo_colors = {
        border = COLOR_WHITE,
        background = Color(100, 60, 0, 222),
        fill = Color(205, 155, 0, 255)
    }

    function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
        -- print("Upgraded DrawHUD")
        if not soulbound:GetNWBool("TTTPAPSoulPowerer") then
            print("Old DrawHUD")
            local OLD_ABILITY = SOULBOUND.PAPOldAbilities[string.sub(ABILITY.Id, 5)]

            return OLD_ABILITY:DrawHUD(soulbound)
        end

        local max_uses = pap_beebarrel_uses:GetInt()
        local uses = soulbound:GetNWInt("TTTSoulboundPap_beebarrelUses", 0)
        local margin = 6
        local ammo_height = 28

        if max_uses == 0 then
            CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
            CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        else
            CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
            CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local ready = true
        local text = "Press '" .. key .. "' to place an *upgraded* bee barrel"
        local next_use = soulbound:GetNWFloat("TTTSoulboundPap_beebarrelNextUse")
        local cur_time = CurTime()

        if max_uses > 0 and uses <= 0 then
            ready = false
            text = "Out of uses"
        elseif cur_time < next_use then
            ready = false
            local s = next_use - cur_time
            local ms = (s - math.floor(s)) * 100
            s = math.floor(s)
            text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
        end

        draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

        return ready
    end
end

SOULBOUND:RegisterAbility(ABILITY)