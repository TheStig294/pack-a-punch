-- Global variable to make setting the PaP camo on entities easier
TTTPAP.camo = "ttt_pack_a_punch/pap_camo"
-- Global table for convar types and names used by upgrades
TTTPAP.convars = TTTPAP.convars or {}

-- List of pre-defined pack a punch upgrades
-- If a weapon's upgrade is not defined, defaults to a 1.5x fire rate upgrade
TTT_PAP_UPGRADES = {
    tfa_dax_big_glock = {
        name = "Giant Glock",
        desc = "Appears so big for everyone else you're a walking gun...",
        firerateMult = 1,
        func = function(SWEP)
            local scale = 10
            local i = 0

            while i < SWEP:GetBoneCount() do
                SWEP:ManipulateBoneScale(i, Vector(scale, scale, scale))
                i = i + 1
            end
        end
    },
    weapon_ars_igniter = {
        name = "Buuuuuurn",
        desc = "Displays the burning elmo meme while held",
        firerateMult = 1,
        func = function(SWEP)
            if SERVER then return end
            SWEP.ElmoMaterial = Material("ttt_pack_a_punch/arsonist_igniter/elmoburn")

            function SWEP:DrawHUDBackground()
                surface.SetAlphaMultiplier(0.1)
                surface.SetDrawColor(39, 39, 39, 39)
                surface.SetMaterial(self.ElmoMaterial)
                surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
                surface.SetAlphaMultiplier(1)
                if isfunction(self.BaseClass.DrawHUD) then return self.BaseClass.DrawHUD(self) end
            end
        end
    },
    weapon_old_dbshotgun = {
        name = "Get off my lawn!",
        desc = "x4 ammo, full-auto, fire-rate up!",
        ammoMult = 4
    },
    weapon_tur_changer = {
        name = "Team + Health Changer",
        desc = "Sets you to 100 health!",
        func = function(SWEP)
            SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

            function SWEP:PrimaryAttack()
                local owner = self:GetOwner()
                SWEP.PAPOldPrimaryAttack(self)

                if SERVER then
                    if not IsValid(owner) then return end
                    owner:SetMaxHealth(100)
                    owner:SetHealth(100)
                end
            end
        end
    },
    weapon_unoreverse = {
        name = "no u",
        desc = "Lasts twice as long",
        noSelectWep = true,
        func = function(SWEP)
            SWEP.UnoReverseLength = GetConVar("ttt_uno_reverse_length"):GetInt() * 2

            if CLIENT then
                SWEP.VElements.v_element.material = TTTPAP.camo
                SWEP.WElements.w_element.material = TTTPAP.camo
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