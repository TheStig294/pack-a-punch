local UPGRADE = {}
UPGRADE.id = "meme_soundboard"
UPGRADE.class = "weapon_discordgift"
UPGRADE.name = "Meme Soundboard"
UPGRADE.desc = "Plays meme sound effects!\nLeft-click: play sound, right-click: change sound"

function UPGRADE:Apply(SWEP)
    SWEP.TTTPAPMemeSounds = file.Find("sound/ttt_pack_a_punch/meme_soundboard/*.mp3", "GAME", "nameasc")
    SWEP.TTTPAPCurrentSound = 1
    SWEP.Primary.Delay = 2
    SWEP.Secondary.Delay = 0.5

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local randomPitch = util.SharedRandom("TTTPAPMemeSoundboard", 75, 125, os.time())
        self:EmitSound("ttt_pack_a_punch/meme_soundboard/" .. self.TTTPAPMemeSounds[self.TTTPAPCurrentSound], 100, randomPitch)
    end

    function SWEP:SecondaryAttack()
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
        self.TTTPAPCurrentSound = self.TTTPAPCurrentSound + 1

        if self.TTTPAPCurrentSound > #self.TTTPAPMemeSounds then
            self.TTTPAPCurrentSound = 1
        end

        if SERVER then return end
        chat.AddText(self.TTTPAPMemeSounds[self.TTTPAPCurrentSound])
    end

    function SWEP:Reload()
    end
end

TTTPAP:Register(UPGRADE)