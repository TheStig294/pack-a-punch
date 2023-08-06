-- Global variable to make setting the PaP camo on entities easier
TTT_PAP_CAMO = "ttt_pack_a_punch/pap_camo"
-- Global table for convar types and names used by upgrades
TTT_PAP_CONVARS = TTT_PAP_CONVARS or {}

-- List of pre-defined pack a punch upgrades
-- If a weapon's upgrade is not defined, defaults to a 1.5x fire rate upgrade
TTT_PAP_UPGRADES = {
    tfa_dax_big_glock = {
        name = "Huge Glock",
        desc = "Appears so huge for everyone else you're a walking gun...",
        firerateMult = 1,
        noCamo = true,
        func = function(SWEP)
            local scale = 10
            local i = 0

            while i < SWEP:GetBoneCount() do
                SWEP:ManipulateBoneScale(i, Vector(scale, scale, scale))
                i = i + 1
            end
        end
    },
    weapon_ttt_binoculars = {
        name = "Eagle's Eye",
        desc = "Faster and further zoom",
        func = function(SWEP)
            if SERVER then
                SWEP.ZoomLevels = {0, 15, 10, 5}

                SWEP.ProcessingDelay = 0.1
            end
        end
    },
    weapon_ttt_confgrenade = {
        name = "The Bristol Pusher",
        desc = "Massive push power, spawns fire!",
        func = function(SWEP)
            if SERVER then
                function SWEP:GetGrenadeName()
                    return "ttt_confgrenade_proj_pap"
                end
            end
        end
    },
    weapon_ttt_glock = {
        name = "Mini-Glock",
        desc = "Big fire rate, ammo, and fire spread increase",
        firerateMult = 1.5,
        spreadMult = 10,
        ammoMult = 2
    },
    weapon_ttt_m16 = {
        name = "Skullcrusher",
        desc = "Ammo + fire rate increase",
        ammoMult = 2,
        firerateMult = 1.2
    },
    weapon_ttt_phammer = {
        name = "The Ghost Ball",
        desc = "x2 ammo + fire rate increase",
        firerateMult = 2,
        ammoMult = 2
    },
    weapon_ttt_sipistol = {
        name = "Unsilenced Pistol",
        desc = "Higher DPS, unsilenced",
        damageMult = 1.5,
        firerateMult = 1.2
    },
    weapon_ttt_smokegrenade = {
        name = "Ninja bomb",
        desc = "Very large smoke cloud",
        func = function(SWEP)
            if SERVER then
                function SWEP:GetGrenadeName()
                    return "ttt_smokegrenade_proj_pap"
                end
            end
        end
    },
    weapon_ttt_teleport = {
        name = "Infini-porter",
        desc = "Effectively unlimited uses",
        ammoMult = 40
    },
    weapon_zm_mac10 = {
        name = "MAC100",
        desc = "Super high fire rate and recoil",
        firerateMult = 2,
        recoilMult = 2
    },
    weapon_zm_molotov = {
        name = "Forever Fire-Nade",
        desc = "Larger explosion, fire lasts a very long time!",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_firegrenade_proj_pap"
            end
        end
    },
    weapon_zm_revolver = {
        name = "The Head Lifter",
        desc = "High recoil, high damage!",
        automatic = false,
        firerateMult = 0.5,
        recoilMult = 2,
        ammoMult = 1.5,
        damageMult = 1.5
    },
    weapon_zm_rifle = {
        name = "Arrhythmic Dirge",
        desc = "Zoomier zoom, fire rate increase!",
        automatic = false,
        firerateMult = 1.2,
        damageMult = 1.5,
        func = function(SWEP)
            if SERVER then
                function SWEP:SetZoom(state)
                    if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
                        if state then
                            self:GetOwner():SetFOV(10, 0.4)
                        else
                            self:GetOwner():SetFOV(0, 0.2)
                        end
                    end
                end
            end
        end
    },
    weapon_zm_shotgun = {
        name = "Dagon's Glare",
        desc = "1.5x ammo, fire rate increase, reload multiple bullets at once!",
        firerateMult = 1.1,
        ammoMult = 1.5,
        func = function(SWEP)
            if SERVER then
                function SWEP:PerformReload()
                    local ply = self:GetOwner()
                    -- prevent normal shooting in between reloads
                    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
                    if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
                    if self:Clip1() >= self.Primary.ClipSize then return end
                    self:GetOwner():RemoveAmmo(math.min(4, self.Primary.ClipSize - self:Clip1()), self.Primary.Ammo, false)
                    self:SetClip1(math.min(self:Clip1() + 4, self.Primary.ClipSize))
                    self:SendWeaponAnim(ACT_VM_RELOAD)
                    self:SetReloadTimer(CurTime() + self:SequenceDuration())
                end
            end
        end
    },
    weapon_zm_sledge = {
        name = "H.U.G.E. 9001",
        desc = "Minimal recoil, higher fire-rate!",
        firerateMult = 1.5,
        recoilMult = 0.1
    }
}