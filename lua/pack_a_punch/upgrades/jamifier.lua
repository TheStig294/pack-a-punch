local UPGRADE = {}
UPGRADE.id = "jamifier"
UPGRADE.class = "weapon_ttt_wpnjammer"
UPGRADE.name = "Jamifier"
UPGRADE.desc = "x3 ammo, turns weapons into jam!"

function UPGRADE:Apply(SWEP)
    self:SetClip(SWEP, 3)
    -- Normally the weapon uses the use key, by default 'E'
    local own = SWEP:GetOwner()

    if IsValid(own) then
        own:PrintMessage(HUD_PRINTCENTER, "Left-click to use")
    end

    function SWEP:Equip()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:PrintMessage(HUD_PRINTCENTER, "Left-click to use")
    end

    SWEP.Primary.Delay = 0.1
    SWEP.Primary.Automatic = false
    SWEP.Primary.Damage = 1

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local ent = owner:GetEyeTrace().Entity
        local wep

        if IsValid(ent) then
            if ent:IsPlayer() then
                -- 1. Try the player's current weapon
                ent:GetActiveWeapon()

                if not IsValid(wep) then
                    -- 2. Try a random weapon the player has
                    for _, w in RandomPairs(ent:GetWeapons()) do
                        if IsValid(w) then
                            wep = w
                            break
                        end
                    end

                    -- 3. If the player has no weapons, print message
                    if not IsValid(wep) then
                        owner:PrintMessage(HUD_PRINTCENTER, "Player has no valid weapons")
                        self:EmitSound("Weapon_Pistol.Empty")

                        return
                    end
                end
            elseif ent:IsWeapon() then
                wep = ent
            else
                owner:PrintMessage(HUD_PRINTCENTER, "Not a weapon!")
                self:EmitSound("Weapon_Pistol.Empty")

                return
            end
        else
            self:EmitSound("Weapon_Pistol.Empty")

            return
        end

        -- If we have a weapon entity, fire away and replace the weapon with jam!
        self.BaseClass.PrimaryAttack(self)

        if SERVER and self:Clip1() <= 0 then
            self:Remove()
            owner:ConCommand("lastinv")
        end
    end

    function SWEP:Deploy()
        return true
    end
end
-- TTTPAP:Register(UPGRADE)