-- Global variable to make setting the PaP camo on entities easier
TTT_PAP_CAMO = "ttt_pack_a_punch/pap_camo"

-- List of pre-defined pack a punch upgrades
-- If a weapon's upgrade is not defined, defaults to a 1.5x fire rate upgrade
TTT_PAP_UPGRADES = {
    weapon_ttt_binoculars = {
        name = "Eagle's Eye",
        func = function(SWEP)
            SWEP.ZoomLevels = {0, 15, 10, 5}

            SWEP.ProcessingDelay = 0.1
        end
    },
    weapon_ttt_confgrenade = {
        name = "The Bristol Pusher",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_confgrenade_proj_pap"
            end
        end
    },
    weapon_ttt_decoy = {
        name = "Does anyone use this?",
        func = function(SWEP)
            function SWEP:PlacedDecoy(decoy)
                decoy:SetMaterial(TTT_PAP_CAMO)
                self:GetOwner().decoy = decoy
                self:TakePrimaryAmmo(1)

                if not self:CanPrimaryAttack() then
                    self:Remove()
                    self.Planted = true
                end
            end
        end
    },
    weapon_ttt_glock = {
        name = "Mini-Glock",
        firerateMult = 1.5,
        spreadMult = 10,
        ammoMult = 2
    },
    weapon_ttt_m16 = {
        name = "Skullcrusher",
        ammoMult = 2,
        firerateMult = 1
    },
    weapon_ttt_phammer = {
        name = "The Ghost Ball",
        ammoMult = 1.5
    },
    weapon_ttt_sipistol = {
        name = "Unsilenced Pistol",
        damageMult = 1.5,
        firerateMult = 1.1
    },
    weapon_ttt_smokegrenade = {
        name = "Ninja bomb",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_smokegrenade_proj_pap"
            end
        end
    },
    weapon_ttt_teleport = {
        name = "Infini-porter",
        ammoMult = 40
    },
    weapon_zm_mac10 = {
        name = "MAC100",
        firerateMult = 2,
        recoilMult = 2
    },
    weapon_zm_molotov = {
        name = "Forever Fire-Nade",
        func = function(SWEP)
            function SWEP:GetGrenadeName()
                return "ttt_firegrenade_proj_pap"
            end
        end
    },
    weapon_zm_revolver = {
        name = "The Head Lifter",
        automatic = false,
        firerateMult = 0.5,
        recoilMult = 2,
        ammoMult = 1.5,
        damageMult = 1.5
    },
    weapon_zm_rifle = {
        name = "Arrhythmic Dirge",
        automatic = false,
        firerateMult = 1.2,
        damageMult = 1.5,
        func = function(SWEP)
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
    },
    weapon_zm_shotgun = {
        name = "Dagon's Glare",
        firerateMult = 1.1,
        ammoMult = 1.5,
        func = function(SWEP)
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
    },
    weapon_zm_sledge = {
        name = "H.U.G.E. 9001",
        firerateMult = 1.3,
        recoilMult = 0.1
    }
}