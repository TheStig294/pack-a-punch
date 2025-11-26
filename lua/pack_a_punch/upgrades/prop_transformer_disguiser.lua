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

    local function SetWeaponFunctions(upgradedDisguiser, disguiser, owner, victim)
        if (SERVER and not IsValid(upgradedDisguiser)) or not IsValid(disguiser) or not IsValid(owner) or not IsValid(victim) then return end
        disguiser:PrimaryAttack()

        if SERVER then
            victim:ChatPrint("Someone permanently turned you into a prop using the upgraded prop disguiser!")
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
            upgradedDisguiser:Remove()
            owner:ConCommand("lastinv")
        end
    end

    if SERVER then
        util.AddNetworkString("TTTPAPPropTransformerDisguiser")
    else
        net.Receive("TTTPAPPropTransformerDisguiser", function()
            local upgradedDisguiser = net.ReadEntity()
            local disguiser = net.ReadEntity()
            local owner = net.ReadPlayer()
            local victim = net.ReadPlayer()
            SetWeaponFunctions(upgradedDisguiser, disguiser, owner, victim)
        end)
    end

    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()
        local victim = owner:GetEyeTrace().Entity

        if UPGRADE:IsPlayer(victim) then
            victim:StripWeapons()
            local disguiser = victim:Give(UPGRADE.class)
            disguiser.TTTPAPPropTransformer = true

            function disguiser:Holster()
                return false
            end

            victim:SelectWeapon(UPGRADE.class)
            owner:PrintMessage(HUD_PRINTCENTER, "Transforming " .. victim:Nick() .. " into a prop...")
            SetWeaponFunctions(self, disguiser, owner, victim)

            timer.Simple(0.1, function()
                net.Start("TTTPAPPropTransformerDisguiser")
                net.WriteEntity(self)
                net.WriteEntity(disguiser)
                net.WritePlayer(owner)
                net.WritePlayer(victim)
                net.Broadcast()
            end)
        end
    end
end

TTTPAP:Register(UPGRADE)