local UPGRADE = {}
UPGRADE.id = "uno_skip"
UPGRADE.class = "weapon_unoreverse"
UPGRADE.name = "UNO Skip"
UPGRADE.desc = "Blocks non-player damage while held\nYou swap weapons with your next attacker!"

function UPGRADE:Apply(SWEP)
    timer.Simple(0, function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        owner:PrintMessage(HUD_PRINTCENTER, "Always active while held!")
    end)

    function SWEP:PrimaryAttack()
    end

    local function GiveWeapons(ply, weps)
        ply:StripWeapons()
        local bestWeapon

        for _, wep in ipairs(weps) do
            -- Make the player automatically select a buy menu item, main gun, or the first weapon from the other player
            if not bestWeapon or wep.Kind == WEAPON_EQUIP or (wep.Kind == WEAPON_HEAVY and bestWeapon.Kind ~= WEAPON_EQUIP) then
                bestWeapon = wep
            end

            local class = WEPS.GetClass(wep)

            if class ~= self.class then
                ply:Give(class)
            end
        end

        -- Try to give the player their new "best" weapon
        -- Selected by priority of:
        -- 1. Buy menu item
        -- 2. Main gun
        -- 3. First gun found
        if bestWeapon then
            ply:SelectWeapon(WEPS.GetClass(bestWeapon))
        end
    end

    self:AddHook("EntityTakeDamage", function(victim, dmg)
        if victim.TTTPAPUnoSkip then return true end
        if not IsPlayer(victim) then return end
        local activeWep = victim:GetActiveWeapon()
        if not IsValid(activeWep) then return end

        if WEPS.GetClass(activeWep) == self.class and self:IsUpgraded(activeWep) then
            local attacker = dmg:GetAttacker()

            if self:IsPlayer(attacker) then
                -- Remove the UNO reverse
                activeWep:Remove()
                -- Alert the victim and attacker
                victim:EmitSound("unoreverse/deflect.mp3")
                victim:PrintMessage(HUD_PRINTCENTER, "Weapons swapped with " .. attacker:Nick() .. "!")
                victim:PrintMessage(HUD_PRINTTALK, "Weapons swapped with " .. attacker:Nick() .. "!")
                attacker:EmitSound("unoreverse/deflect.mp3")
                attacker:PrintMessage(HUD_PRINTCENTER, "Weapons swapped with " .. victim:Nick() .. "!")
                attacker:PrintMessage(HUD_PRINTTALK, "Weapons swapped with " .. victim:Nick() .. "!")
                -- Swap the weapons of the victim and attacker
                local victimWeps = victim:GetWeapons()
                GiveWeapons(victim, attacker:GetWeapons())
                GiveWeapons(attacker, victimWeps)
            end

            -- For some reason some weapons have this hook called twice and only actually deal damage on the 2nd call (Like the crowbar)
            -- This means the actual damage isn't negated since the player's weapon is invalid by the weapon swapping,
            -- so this code block doesn't get called on the 2nd call where the actual damage occurs
            victim.TTTPAPUnoSkip = true

            timer.Simple(0.1, function()
                victim.TTTPAPUnoSkip = false
            end)

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)