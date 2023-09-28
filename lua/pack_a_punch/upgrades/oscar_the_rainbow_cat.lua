local UPGRADE = {}
UPGRADE.id = "oscar_the_rainbow_cat"
UPGRADE.class = "weapon_valenok"
UPGRADE.name = "Oscar The Rainbow Cat"
UPGRADE.desc = "Do do do do doooo..."
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    SWEP.PAPMaxwellSound = Sound("ttt_pack_a_punch/oscar_the_rainbow_cat/maxwell_theme.mp3")
    SWEP:EmitSound(SWEP.PAPMaxwellSound)
    SWEP.PAPOldDeploy = SWEP.Deploy

    function SWEP:Deploy()
        self:PAPOldDeploy()
        self:EmitSound(self.PAPMaxwellSound)
    end

    SWEP.PAPOldHolster = SWEP.Holster

    function SWEP:Holster()
        self:PAPOldHolster()
        self:StopSound(self.PAPMaxwellSound)

        return true
    end

    SWEP.PAPOldOnRemove = SWEP.OnRemove

    function SWEP:OnRemove()
        self:PAPOldOnRemove()
        self:StopSound(self.PAPMaxwellSound)
    end

    -- Changes a player's weapons colours over time
    SWEP.PAPRainbowPhase = 1
    SWEP.PAPSetInitialColour = false
    SWEP.PAPMult = 1
    SWEP.PAPOldThink = SWEP.Think

    function SWEP:Think()
        self:PAPOldThink()
        if SERVER then return end

        if not self.PAPSetInitialColour then
            self.VElements.catty.color.r = 255
            self.VElements.catty.color.b = 0
            self.VElements.catty.color.g = 0
            self.PAPSetInitialColour = true
        end

        local colour = self.VElements.catty.color

        if self.PAPRainbowPhase == 1 then
            colour.b = colour.b + self.PAPMult

            if colour.b == 255 then
                self.PAPRainbowPhase = 2
            end
        elseif self.PAPRainbowPhase == 2 then
            colour.r = colour.r - self.PAPMult

            if colour.r == 0 then
                self.PAPRainbowPhase = 3
            end
        elseif self.PAPRainbowPhase == 3 then
            colour.g = colour.g + self.PAPMult

            if colour.g == 255 then
                self.PAPRainbowPhase = 4
            end
        elseif self.PAPRainbowPhase == 4 then
            colour.b = colour.b - self.PAPMult

            if colour.b == 0 then
                self.PAPRainbowPhase = 5
            end
        elseif self.PAPRainbowPhase == 5 then
            colour.r = colour.r + self.PAPMult

            if colour.r == 255 then
                self.PAPRainbowPhase = 6
            end
        elseif self.PAPRainbowPhase == 6 then
            colour.g = colour.g - self.PAPMult

            if colour.g == 0 then
                self.PAPRainbowPhase = 1
            end
        end

        self.WElements.catty.color = colour
        self.VElements.catty.color = colour
    end
end

TTTPAP:Register(UPGRADE)