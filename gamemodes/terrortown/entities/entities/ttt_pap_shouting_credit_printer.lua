AddCSLuaFile()
ENT.Base = "ent_credit_printer"
ENT.Type = "anim"
ENT.PrintName = "Shouting Credit Printer"

local lengthMult = CreateConVar("pap_shouting_credit_printer_length_mult", 2, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Times faster printing credits", 0.1, 5)

local maxCreditsCvar = CreateConVar("pap_shouting_credit_printer_max_credits", 4, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max number of printed credits", 0, 20)

local soundsCvar = CreateConVar("pap_shouting_credit_printer_sounds", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Play the extra sounds?", 0, 1)

function ENT:Initialize()
    self:SetPAPCamo()
    self.PrintRate = GetConVar("ttt_printer_printduration"):GetInt() / lengthMult:GetFloat()
    self.MaxCredits = maxCreditsCvar:GetInt()
    self.BaseClass.Initialize(self)

    if SERVER and IsFirstTimePredicted() and soundsCvar:GetBool() then
        local quotes = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

        table.Shuffle(quotes)
        local timername = "TTTPAPShoutingCreditPrinterNoise" .. self:EntIndex()
        local quoteNum = 1

        timer.Create("TTTPAPShoutingCreditPrinterNoise" .. self:EntIndex(), 10, 0, function()
            if IsValid(self) then
                self:EmitSound("ttt_pack_a_punch/shouting_credit_printer/quote" .. quotes[quoteNum] .. ".mp3")
                self:EmitSound("ttt_pack_a_punch/shouting_credit_printer/quote" .. quotes[quoteNum] .. ".mp3")
                self:EmitSound("ttt_pack_a_punch/shouting_credit_printer/quote" .. quotes[quoteNum] .. ".mp3")
                quoteNum = quoteNum + 1

                if quoteNum > 11 then
                    timer.Remove(timername)
                end
            else
                timer.Remove(timername)
            end
        end)
    end
end