local UPGRADE = {}
UPGRADE.id = "oscar_the_rainbow_cat"
UPGRADE.class = "weapon_valenok"
UPGRADE.name = "Oscar The Rainbow Cat"
UPGRADE.desc = "Do do do do doooo..."
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    -- SWEP.PAPMaxwellSound = Sound("ttt_pack_a_punch/oscar_the_rainbow_cat/maxwell_theme.mp3")
    -- SWEP:EmitSound(SWEP.PAPMaxwellSound)
    -- function SWEP:Deploy()
    --     self:EmitSound(self.PAPMaxwellSound)
    -- end
    -- function SWEP:Holster()
    --     self:StopSound(self.PAPMaxwellSound)
    --     return true
    -- end
    -- function SWEP:OnRemove()
    --     self:StopSound(self.PAPMaxwellSound)
    -- end
    -- Changes a player's weapons colours over time
    SWEP.PAPRainbowPhase = 1
    SWEP.PAPSetInitialColour = false
    SWEP.PAPMult = 1
    SWEP.PAPHalfMult = SWEP.PAPMult / 2

    self:AddHook("PreDrawViewModel", function(vm, weapon, ply)
        if not self.PAPSetInitialColour then
            vm:SetColor(COLOR_WHITE)
            self.PAPSetInitialColour = true
        end

        local colour = vm:GetColor()

        if self.PAPRainbowPhase == 1 then
            colour.r = colour.r + self.PAPMult
            colour.g = colour.g - self.PAPHalfMult
            colour.b = colour.b - self.PAPMult

            if colour.r + self.PAPMult == 255 then
                self.PAPRainbowPhase = 2
            end
        elseif self.PAPRainbowPhase == 2 then
            colour.r = colour.r - self.PAPMult
            colour.g = colour.g + self.PAPMult
            colour.b = colour.b - self.PAPHalfMult

            if colour.g + self.PAPMult == 255 then
                self.PAPRainbowPhase = 3
            end
        elseif self.PAPRainbowPhase == 3 then
            colour.r = colour.r - self.PAPHalfMult
            colour.g = colour.g - self.PAPMult
            colour.b = colour.b + self.PAPMult

            if colour.b + self.PAPMult == 255 then
                self.PAPRainbowPhase = 1
            end
        end

        vm:SetColor(colour)
    end)
end

TTTPAP:Register(UPGRADE)