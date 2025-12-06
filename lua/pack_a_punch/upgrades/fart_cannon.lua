local UPGRADE = {}
UPGRADE.id = "fart_cannon"
UPGRADE.class = "tfa_scavenger"
UPGRADE.name = "Fart Cannon"
UPGRADE.desc = "Extra ammo, plays fart noises"
UPGRADE.ammoMult = 2

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()

    self:AddHook("EntityEmitSound", function(EmitSoundInfo)
        if EmitSoundInfo.SoundName == "weapons/ubersniper/ubersniper_proj_windup.ogg" then
            EmitSoundInfo.SoundName = "ttt_pack_a_punch/fart_cannon/windup.mp3"
            sound.Play("ttt_pack_a_punch/fart_cannon/windup.mp3", Vector(0, 0, 0), 0, 100, 1)
            sound.Play("ttt_pack_a_punch/fart_cannon/windup.mp3", Vector(0, 0, 0), 0, 100, 1)

            return true
        elseif EmitSoundInfo.SoundName == "weapons/ubersniper/ubersniper_explode_pap.ogg" then
            EmitSoundInfo.SoundName = "ttt_pack_a_punch/fart_cannon/fart.mp3"
            sound.Play("ttt_pack_a_punch/fart_cannon/fart.mp3", Vector(0, 0, 0), 0, 100, 1)
            sound.Play("ttt_pack_a_punch/fart_cannon/fart.mp3", Vector(0, 0, 0), 0, 100, 1)

            return true
        end
    end)
end

TTTPAP:Register(UPGRADE)