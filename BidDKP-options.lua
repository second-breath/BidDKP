
function BidDKP_isAutoCloseWindow() 
	return BidDKP_AutoCloseWindow == 1
end 

function BidDKP_isPreventSelfOverbid()
	return BidDKP_PreventSelfOverbid == 1
end	

function BidDKP_HandleCheckbox(checkbox)
	local checkboxname = checkbox:GetName();


	if checkboxname == "BidDKPOptionsFrameEnableAutoClose" then
		if checkbox:GetChecked() then
			BidDKP_AutoCloseWindow = 1;
		else
			BidDKP_AutoCloseWindow = 0;
		end
		return;
	end

    
	if checkboxname == "BidDKPOptionsFramePreventSelfOverbid" then
		if checkbox:GetChecked() then
			BidDKP_PreventSelfOverbid = 1;
		else
			BidDKP_PreventSelfOverbid = 0;
		end
		return;
	end

end


function BidDKP_InitializeConfigSettings(object)
    if not BidDKP_AutoCloseWindow then
        BidDKP_AutoCloseWindow = 1
    end

    if not BidDKP_PreventSelfOverbid then 
        BidDKP_PreventSelfOverbid = 1
    end

	getglobal("BidDKPOptionsFrameEnableAutoClose"):SetChecked(BidDKP_AutoCloseWindow)
	getglobal("BidDKPOptionsFramePreventSelfOverbid"):SetChecked(BidDKP_PreventSelfOverbid)

	return
end
