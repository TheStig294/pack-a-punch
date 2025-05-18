local UPGRADE = {}
UPGRADE.id = "potion_night_vision"
UPGRADE.class = "weapon_ttt_mc_invispotion"
UPGRADE.name = "Night Vision Pot."
UPGRADE.desc = "Lets you see players though walls!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPNightVisionPotion")
    end

    local HealSound1 = "minecraft_original/invisible_end.wav"
    local HealSound2 = "minecraft_original/invisible_start.wav"
    local DestroySound = "minecraft_original/glass2.wav"
    local mc_invis_tick_rate = GetConVar("ttt_mc_invis_tick_rate")

    function SWEP:InvisibilityEnable()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        if SERVER and not self.PotionEnabled then
            net.Start("TTTPAPNightVisionPotion")
            net.WriteBool(true)
            net.Send(owner)
        end

        self:EmitSound(HealSound2)
        self:TakePrimaryAmmo(1)
        self.PotionEnabled = true
        local tickRate = mc_invis_tick_rate:GetFloat()
        local timername = "use_ammo" .. self:EntIndex()

        timer.Create("use_ammo" .. self:EntIndex(), tickRate, 0, function()
            if not IsValid(self) then
                timer.Remove(timername)

                return
            end

            if self:Clip1() <= self.MaxAmmo then
                self:SetClip1(math.min(self:Clip1() - 1, self.MaxAmmo))
            end

            if self:Clip1() <= 0 then
                self:InvisibilityDisable()

                if SERVER then
                    self:Remove()
                end

                self:EmitSound(DestroySound)
            end
        end)
    end

    function SWEP:InvisibilityDisable()
        -- Only play the sound if we're enabled, but run everything else
        -- so we're VERY SURE this disables
        if self.PotionEnabled then
            self:EmitSound(HealSound1)
        end

        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:SetColor(COLOR_WHITE)
            owner:SetMaterial("")

            if SERVER and self.PotionEnabled then
                net.Start("TTTPAPNightVisionPotion")
                net.WriteBool(false)
                net.Send(owner)
            end
        end

        timer.Remove("use_ammo" .. self:EntIndex())
        self.PotionEnabled = false
    end

    if CLIENT then
        net.Receive("TTTPAPNightVisionPotion", function()
            local enable = net.ReadBool()

            if enable then
                self:AddHook("PreDrawHalos", function()
                    local plys = {}

                    for _, ply in player.Iterator() do
                        if self:IsAlive(ply) then
                            table.insert(plys, ply)
                        end
                    end

                    halo.Add(plys, Color(255, 255, 255), 0, 0, 1, true, true)
                end)
            else
                self:RemoveHook("PreDrawHalos")
            end
        end)

        if not SWEP.PAPOldDrawWorldModel then
            SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

            function SWEP:DrawWorldModel()
                SWEP:PAPOldDrawWorldModel()

                if IsValid(self.WorldModelEnt) then
                    self.WorldModelEnt:SetPAPCamo()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)