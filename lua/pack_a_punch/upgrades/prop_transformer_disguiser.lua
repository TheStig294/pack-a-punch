local UPGRADE = {}
UPGRADE.id = "prop_transformer_disguiser"
UPGRADE.class = "weapon_ttt_prop_disguiser_2"
UPGRADE.name = "Prop Transformer"
UPGRADE.desc = "Permanently transforms someone else into a prop!"

function UPGRADE:Apply(SWEP)
    self:AddHook("PlayerCanPickupWeapon", function(ply, _)
        local disguiser = ply:GetWeapon(UPGRADE.class)
        if IsValid(disguiser) and disguiser.TTTPAPPropTransformer then return false end
    end)

    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()

        if SERVER and owner.LagCompensation then
            owner:LagCompensation(true)
        end

        local victim = UPGRADE:GetLookedAtEntity(owner)

        if SERVER and owner.LagCompensation then
            owner:LagCompensation(false)
        end

        print(owner, victim)

        if UPGRADE:IsPlayer(victim) then
            if SERVER then
                victim:StripWeapons()
                local disguiser = victim:Give(UPGRADE.class)
                disguiser.TTTPAPPropTransformer = true

                function disguiser:Holster()
                    return false
                end

                victim:SelectWeapon(UPGRADE.class)
                owner:PrintMessage(HUD_PRINTCENTER, "Transforming " .. victim:Nick() .. " into a prop...")
            end

            timer.Simple(2, function()
                print(self, owner, victim)
                if not IsValid(self) or not IsValid(owner) or not IsValid(victim) then return end
                local disguiser = victim:GetWeapon(UPGRADE.class)
                print(disguiser)
                if not IsValid(disguiser) then return end
                disguiser:PrimaryAttack()

                if SERVER then
                    victim:ChatPrint("Someone permanently turned you into a prop using the upgraded prop disguiser!")
                    owner:PrintMessage(HUD_PRINTCENTER, victim:Nick() .. " transformed!")
                end

                disguiser.AllowDrop = false

                function disguiser:SecondaryAttack()
                    if CLIENT then return end
                    self:GetOwner():PrintMessage(HUD_PRINTCENTER, "You're stuck as a prop, go hide!")
                end

                function disguiser:OnDrop()
                    if SERVER then
                        self:Remove()
                    end
                end

                function disguiser:ShouldDropOnDie()
                    return false
                end

                function disguiser:Holster()
                    return false
                end

                if SERVER then
                    self:Remove()
                    owner:ConCommand("lastinv")
                end
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)