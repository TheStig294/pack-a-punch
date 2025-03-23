local UPGRADE = {}
UPGRADE.id = "instant_handcuffs"
UPGRADE.class = "weapon_ttt_handcuffs"
UPGRADE.name = "Instant Handcuffs"

UPGRADE.convars = {
    {
        name = "pap_instant_handcuffs_secs",
        type = "int"
    }
}

local secsCvar = CreateConVar("pap_instant_handcuffs_secs", 10, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds players remain handcuffed", 1, 30)

UPGRADE.desc = "Handcuffs everyone else for " .. secsCvar:GetInt() .. " seconds!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end

    local saveBlocklist = {"weapon_zm_carry", "weapon_ttt_unarmed"}

    local playerNonDroppables = {}

    local function ReleasePlayer(ply)
        ply:SetNWBool("IsCuffed", false)
        ply:SetNWEntity("CuffedBy", nil)
        ply:SetNWBool("WasCuffed", true)
        local sid64 = ply:SteamID64()
        local hasCrowbar = false

        if playerNonDroppables[sid64] then
            for _, data in ipairs(playerNonDroppables[sid64]) do
                local wep = ply:Give(data.class)
                wep:SetClip1(data.clip1)
                wep:SetClip2(data.clip2)

                if data.class == "weapon_kil_crowbar" then
                    hasCrowbar = true
                end
            end

            playerNonDroppables[sid64] = nil
        end

        if not hasCrowbar then
            ply:Give("weapon_zm_improvised")
        end

        ply:Give("weapon_zm_carry")
        ply:Give("weapon_ttt_unarmed")
        ply:PrintMessage(HUD_PRINTCENTER, "You are released.")
    end

    local function CuffPlayer(target, owner)
        if target:IsValid() and (target:IsPlayer() or target:IsNPC()) then
            if not IsValid(owner) then return end
            target:SetNWBool("IsCuffed", true)
            target:SetNWEntity("CuffedBy", owner)
            target:PrintMessage(HUD_PRINTCENTER, "You was all cuffed.")
            target:EmitSound("npc/metropolice/vo/holdit.wav", 50, 100)
            local time = secsCvar:GetInt()

            timer.Create(target:Nick() .. "_EndCuffed", time, 1, function()
                if target:IsValid() and (target:IsPlayer() or target:IsNPC()) and target:GetNWBool("IsCuffed", false) then
                    ReleasePlayer(target)

                    if IsValid(owner) then
                        owner:PrintMessage(HUD_PRINTCENTER, time .. " seconds are up, everyone has been released.")
                    end
                end
            end)

            hook.Call("TTTPlayerHandcuffed", nil, owner, target, time)
            local sid64 = target:SteamID64()
            playerNonDroppables[sid64] = {}

            for _, v in pairs(target:GetWeapons()) do
                local class = v:GetClass()

                -- Don't drop crowbar since a new one is given
                if class ~= "weapon_zm_improvised" then
                    -- Only drop droppables (but skip the Killer crowbar)
                    if v.AllowDrop and class ~= "weapon_kil_crowbar" then
                        target:DropWeapon(v)
                        -- Save everything else to give back to the player later
                    elseif not table.HasValue(saveBlocklist, class) then
                        table.insert(playerNonDroppables[sid64], {
                            class = class,
                            clip1 = v:Clip1(),
                            clip2 = v:Clip2()
                        })
                    end
                end

                target:StripWeapon(class)
            end
        end
    end

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        for _, ply in player.Iterator() do
            if not UPGRADE:IsAlive(ply) then continue end

            if ply ~= owner then
                CuffPlayer(ply, owner)
            end
        end

        if IsValid(self) then
            self:Remove()
        end
    end
end

TTTPAP:Register(UPGRADE)