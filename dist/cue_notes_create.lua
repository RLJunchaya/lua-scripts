local a,b,c,d=(function(e)local f={[{}]=true}local g;local h={}local require;local i={}g=function(j,k)if not h[j]then h[j]=k end end;require=function(j)local l=i[j]if l then if l==f then return nil end else if not h[j]then if not e then local m=type(j)=='string'and'\"'..j..'\"'or tostring(j)error('Tried to require '..m..', but no such module has been registered')else return e(j)end end;i[j]=f;l=h[j](require,i,g,h)i[j]=l end;return l end;return require,i,g,h end)(require)c("__root",function(require,n,c,d)function plugindef()finaleplugin.RequireSelection=true;finaleplugin.Author="Carl Vine"finaleplugin.AuthorURL="http://carlvine.com"finaleplugin.Copyright="CC0 https://creativecommons.org/publicdomain/zero/1.0/"finaleplugin.Version="v0.64"finaleplugin.Date="2022/07/11"finaleplugin.Notes=[[
        This script is keyboard-centred requiring minimal mouse action. 
        It takes music in Layer 1 from one staff in the selected region and creates a "Cue" version on another chosen staff. 
        The cue copy is reduced in size and muted, and can duplicate chosen markings from the original. 
        It is shifted to the chosen layer with a (real) whole-note rest placed in layer 1.

        Your choices are saved after each script run in your user preferences folder. 
        If using RGPLua (v0.58+) the script automatically creates a new expression category 
        called "Cue Names" if it does not exist. 
        If using JWLua, before running the script you must create an Expression Category 
        called "Cue Names" containing at least one text expression.
    ]]return"Cue Notes Create…","Cue Notes Create","Copy as cue notes to another staff"end;local o={copy_articulations=false,copy_expressions=false,copy_smartshapes=false,copy_slurs=true,copy_clef=false,mute_cuenotes=true,cuenote_percent=70,cuenote_layer=3,freeze_up_down=0,cue_category_name="Cue Names",cue_font_smaller=1}local p=require("library.configuration")local q=require("library.clef")local r=require("library.layer")p.get_user_settings("cue_notes_create",o,true)function show_error(s)local t={only_one_staff="Please select just one staff\n as the source for the new cue",empty_region="Please select a region\nwith some notes in it!",first_make_expression_category="You must first create a new Text Expression Category called \""..o.cue_category_name.."\" containing at least one entry"}finenv.UI():AlertNeutral("script: "..plugindef(),t[s])return-1 end;function should_overwrite_existing_music()local u=finenv.UI():AlertOkCancel("script: "..plugindef(),"Overwrite existing music?")local v=u==0;return v end;function region_is_empty(w)for x in eachentry(w)do if x.Count>0 then return false end end;return true end;function new_cue_name(y)local z=finale.FCCustomWindow()local A=finale.FCString()A.LuaString=plugindef()z:SetTitle(A)A.LuaString="New cue name:"z:CreateStatic(0,20):SetText(A)local B=z:CreateEdit(0,40)B:SetWidth(200)local C=finale.FCStaff()C:Load(y)B:SetText(C:CreateDisplayFullNameString())z:CreateOkButton()z:CreateCancelButton()local D=z:ExecuteModal(nil)==finale.EXECMODAL_OK;B:GetText(A)return D,A.LuaString end;function choose_name_index(E)local z=finale.FCCustomWindow()local A=finale.FCString()A.LuaString=plugindef()z:SetTitle(A)A.LuaString="Select cue name:"z:CreateStatic(0,20):SetText(A)local F=z:CreateListBox(0,40)F:SetWidth(200)A.LuaString="*** new name ***"F:AddString(A)for G,H in ipairs(E)do A.LuaString=H[1]F:AddString(A)end;z:CreateOkButton()z:CreateCancelButton()local D=z:ExecuteModal(nil)==finale.EXECMODAL_OK;return D,F:GetSelectedItem()end;function create_new_expression(I,J)local K=finale.FCCategoryDef()K:Load(J)local L=K:CreateTextFontInfo()local A=finale.FCString()A.LuaString="^fontTxt"..L:CreateEnigmaString(finale.FCString()).LuaString..I;local M=finale.FCTextExpressionDef()M:SaveNewTextBlock(A)M:AssignToCategory(K)M:SetUseCategoryPos(true)M:SetUseCategoryFont(true)M:SaveNew()return M:GetItemNo()end;function choose_destination_staff(y)local F={}local N=finenv.Region()local O=N.StartSlot;N:SetFullMeasureStack()local C=finale.FCStaff()for P=N.StartSlot,N.EndSlot do local Q=N:CalcStaffNumber(P)if Q~=y then C:Load(Q)table.insert(F,{Q,C:CreateDisplayFullNameString().LuaString})end end;N.StartSlot=O;N.EndSlot=O;local R={210,310,360}local S=20;local T=finenv.UI():IsOnMac()and 3 or 0;local U={"copy_articulations","copy_expressions","copy_smartshapes","copy_slurs","copy_clef","mute_cuenotes","cuenote_percent","cuenote_layer","freeze_up_down"}local V=6;local W={}local A=finale.FCString()local z=finale.FCCustomLuaWindow()A.LuaString=plugindef()z:SetTitle(A)local X=z:CreateStatic(0,0)A.LuaString="Select destination staff:"X:SetText(A)X:SetWidth(200)local Y=z:CreateListBox(0,S)Y.UseCheckboxes=true;Y:SetWidth(200)for G,H in ipairs(F)do A.LuaString=H[2]Y:AddString(A)end;A.LuaString="Cue Options:"z:CreateStatic(R[1],0):SetText(A)for G,H in ipairs(U)do A.LuaString=string.gsub(H,'_',' ')if G<=V then W[G]=z:CreateCheckbox(R[1],G*S)W[G]:SetText(A)W[G]:SetWidth(120)local Z=o[H]and 1 or 0;W[G]:SetCheck(Z)elseif G<#U then A.LuaString=A.LuaString..":"z:CreateStatic(R[1],G*S):SetText(A)W[G]=z:CreateEdit(R[2],G*S-T)W[G]:SetInteger(o[H])W[G]:SetWidth(50)end end;local _=z:CreatePopup(R[1],#U*S+5)A.LuaString="Stems: normal"_:AddString(A)A.LuaString="Stems: freeze up"_:AddString(A)A.LuaString="Stems: freeze down"_:AddString(A)_:SetWidth(160)_:SetSelectedItem(o.freeze_up_down)local a0=z:CreateButton(R[3],S*2)A.LuaString="Clear All"a0:SetWidth(80)a0:SetText(A)z:RegisterHandleControlEvent(a0,function()for G=1,V do W[G]:SetCheck(0)end;Y:SetKeyboardFocus()end)local a1=z:CreateButton(R[3],S*4)A.LuaString="Set All"a1:SetWidth(80)a1:SetText(A)z:RegisterHandleControlEvent(a1,function()for G=1,V do W[G]:SetCheck(1)end;Y:SetKeyboardFocus()end)z:CreateOkButton()z:CreateCancelButton()local D=z:ExecuteModal(nil)==finale.EXECMODAL_OK;local a2=Y:GetSelectedItem()local a3=F[a2+1][1]for G,H in ipairs(U)do if G<=V then o[H]=W[G]:GetCheck()==1 elseif G<#U then local a4=W[G]:GetInteger()if G==#W and(a4<2 or a4>4)then a4=4 end;o[H]=a4 end end;o.freeze_up_down=_:GetSelectedItem()return D,a3 end;function fix_text_expressions(w)local a5=finale.FCExpressions()a5:LoadAllForRegion(w)for a6 in eachbackwards(a5)do if a6.StaffGroupID==0 then if o.copy_expressions then a6.LayerAssignment=o.cuenote_layer;a6.ScaleWithEntry=true;a6:Save()else a6:DeleteData()end end end end;function copy_to_destination(a7,a8)local a9=finale.FCMusicRegion()a9:SetRegion(a7)a9:CopyMusic()a9.StartStaff=a8;a9.EndStaff=a8;if not region_is_empty(a9)and not should_overwrite_existing_music()then a9:ReleaseMusic()return false end;a9:PasteMusic()a9:ReleaseMusic()for aa=2,4 do r.clear(a9,aa)end;for x in eachentrysaved(a9)do if x:IsNote()and o.mute_cuenotes then x.Playback=false end;x:SetNoteDetailFlag(true)local ab=finale.FCEntryAlterMod()ab:SetNoteEntry(x)ab:SetResize(o.cuenote_percent)ab:Save()if not o.copy_articulations and x:GetArticulationFlag()then for ac in each(x:CreateArticulations())do ac:DeleteData()end;x:SetArticulationFlag(false)end;if o.freeze_up_down>0 then x.FreezeStem=true;x.StemUp=o.freeze_up_down==1 end end;r.swap(a9,1,o.cuenote_layer)if not o.copy_clef then q.restore_default_clef(a9.StartMeasure,a9.EndMeasure,a8)end;fix_text_expressions(a9)if not o.copy_smartshapes or not o.copy_slurs then local ad=finale.FCSmartShapeMeasureMarks()ad:LoadAllForRegion(a9,true)for ae in each(ad)do local af=ae:CreateSmartShape()if af:IsSlur()and not o.copy_slurs or not af:IsSlur()and not o.copy_smartshapes then af:DeleteData()end end end;for ag=a9.StartMeasure,a9.EndMeasure do local ah=finale.FCNoteEntryCell(ag,a8)ah:Load()local ai=ah:AppendEntriesInLayer(1,1)if ai then ai.Duration=finale.WHOLE_NOTE;ai.Legality=true;ai:MakeRest()ah:Save()end end;return true end;function new_expression_category(aj)local D=false;local ak=0;if not finenv.IsRGPLua then return D,ak end;local al=finale.FCCategoryDef()al:Load(finale.DEFAULTCATID_TECHNIQUETEXT)local A=finale.FCString()A.LuaString=aj;al:SetName(A)al:SetVerticalAlignmentPoint(finale.ALIGNVERT_STAFF_REFERENCE_LINE)al:SetVerticalBaselineOffset(30)al:SetHorizontalAlignmentPoint(finale.ALIGNHORIZ_CLICKPOS)al:SetHorizontalOffset(-18)local L=al:CreateTextFontInfo()L.Size=L.Size-o.cue_font_smaller;al:SetTextFontInfo(L)D=al:SaveNewWithType(finale.DEFAULTCATID_TECHNIQUETEXT)if D then ak=al:GetID()end;return D,ak end;function assign_expression_to_staff(Q,am,an,ao)local ap=finale.FCExpression()ap:SetStaff(Q)ap:SetVisible(true)ap:SetMeasurePos(an)ap:SetScaleWithEntry(false)ap:SetPartAssignment(true)ap:SetScoreAssignment(true)ap:SetID(ao)ap:SaveNewToCell(finale.FCCell(am,Q))end;function create_cue_notes()local aq={}local a7=finenv.Region()local ar=a7.StartStaff;local D,as,at,au,av,aw,a8,ap;if a7:CalcStaffSpan()>1 then return show_error("only_one_staff")elseif region_is_empty(a7)then return show_error("empty_region")end;as=finale.FCCategoryDef()at=finale.FCTextExpressionDefs()at:LoadAll()for ax in each(at)do as:Load(ax.CategoryID)if string.find(as:CreateName().LuaString,o.cue_category_name)then au=ax.CategoryID;local A=ax:CreateTextString()A:TrimEnigmaTags()table.insert(aq,{A.LuaString,ax.ItemNo})end end;if#aq==0 then D,au=new_expression_category(o.cue_category_name)if not D then return show_error("first_make_expression_category")end end;D,aw=choose_name_index(aq)if not D then return end;if aw==0 then D,ap=new_cue_name(ar)if not D or ap==""then return end;av=create_new_expression(ap,au)else av=aq[aw][2]end;D,a8=choose_destination_staff(ar)if not D then return end;p.save_user_settings("cue_notes_create",o)if not copy_to_destination(a7,a8)then return end;assign_expression_to_staff(a8,a7.StartMeasure,0,av)a7:SetInDocument()end;create_cue_notes()end)c("library.layer",function(require,n,c,d)local ay={}function ay.finale_version(az,aA,aB)local aC=bit32.bor(bit32.lshift(math.floor(az),24),bit32.lshift(math.floor(aA),20))if aB then aC=bit32.bor(aC,math.floor(aB))end;return aC end;function ay.group_overlaps_region(aD,w)if w:IsFullDocumentSpan()then return true end;local aE=false;local aF=finale.FCSystemStaves()aF:LoadAllForRegion(w)for aG in each(aF)do if aD:ContainsStaff(aG:GetStaff())then aE=true;break end end;if not aE then return false end;if aD.StartMeasure>w.EndMeasure or aD.EndMeasure<w.StartMeasure then return false end;return true end;function ay.group_is_contained_in_region(aD,w)if not w:IsStaffIncluded(aD.StartStaff)then return false end;if not w:IsStaffIncluded(aD.EndStaff)then return false end;return true end;function ay.staff_group_is_multistaff_instrument(aD)local aH=finale.FCMultiStaffInstruments()aH:LoadAll()for aI in each(aH)do if aI:ContainsStaff(aD.StartStaff)and aI.GroupID==aD:GetItemID()then return true end end;return false end;function ay.get_selected_region_or_whole_doc()local aJ=finenv.Region()if aJ:IsEmpty()then aJ:SetFullDocument()end;return aJ end;function ay.get_first_cell_on_or_after_page(aK)local aL=aK;local aM=finale.FCPage()local aN=false;while aM:Load(aL)do if aM:GetFirstSystem()>0 then aN=true;break end;aL=aL+1 end;if aN then local aO=finale.FCStaffSystem()aO:Load(aM:GetFirstSystem())return finale.FCCell(aO.FirstMeasure,aO.TopStaff)end;local aP=finale.FCMusicRegion()aP:SetFullDocument()return finale.FCCell(aP.EndMeasure,aP.EndStaff)end;function ay.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local aQ=finale.FCMusicRegion()aQ:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),aQ.StartStaff)end;return ay.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function ay.get_top_left_selected_or_visible_cell()local aJ=finenv.Region()if not aJ:IsEmpty()then return finale.FCCell(aJ.StartMeasure,aJ.StartStaff)end;return ay.get_top_left_visible_cell()end;function ay.is_default_measure_number_visible_on_cell(aR,aS,aT,aU)local C=finale.FCCurrentStaffSpec()if not C:LoadForCell(aS,0)then return false end;if aR:GetShowOnTopStaff()and aS.Staff==aT.TopStaff then return true end;if aR:GetShowOnBottomStaff()and aS.Staff==aT:CalcBottomStaff()then return true end;if C.ShowMeasureNumbers then return not aR:GetExcludeOtherStaves(aU)end;return false end;function ay.is_default_number_visible_and_left_aligned(aR,aS,aV,aU,aW)if aR.UseScoreInfoForParts then aU=false end;if aW and aR:GetShowOnMultiMeasureRests(aU)then if finale.MNALIGN_LEFT~=aR:GetMultiMeasureAlignment(aU)then return false end elseif aS.Measure==aV.FirstMeasure then if not aR:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=aR:GetStartAlignment(aU)then return false end else if not aR:GetShowMultiples(aU)then return false end;if finale.MNALIGN_LEFT~=aR:GetMultipleAlignment(aU)then return false end end;return ay.is_default_measure_number_visible_on_cell(aR,aS,aV,aU)end;function ay.update_layout(aX,aY)aX=aX or 1;aY=aY or false;local aZ=finale.FCPage()if aZ:Load(aX)then aZ:UpdateLayout(aY)end end;function ay.get_current_part()local a_=finale.FCParts()a_:LoadAll()return a_:GetCurrent()end;function ay.get_page_format_prefs()local b0=ay.get_current_part()local b1=finale.FCPageFormatPrefs()local b2=false;if b0:IsScore()then b2=b1:LoadScore()else b2=b1:LoadParts()end;return b1,b2 end;local b3=function(b4)local b5=finenv.UI():IsOnWindows()local b6=function(b7,b8)if finenv.UI():IsOnWindows()then return b7 and os.getenv(b7)or""else return b8 and os.getenv(b8)or""end end;local b9=b4 and b6("LOCALAPPDATA","HOME")or b6("COMMONPROGRAMFILES")if not b5 then b9=b9 .."/Library/Application Support"end;b9=b9 .."/SMuFL/Fonts/"return b9 end;function ay.get_smufl_font_list()local ba={}local bb=function(b4)local b9=b3(b4)local bc=function()if finenv.UI():IsOnWindows()then return io.popen('dir "'..b9 ..'" /b /ad')else return io.popen('ls "'..b9 ..'"')end end;local bd=function(be)local bf=finale.FCString()bf.LuaString=be;return finenv.UI():IsFontAvailable(bf)end;for be in bc():lines()do if not be:find("%.")then be=be:gsub(" Bold","")be=be:gsub(" Italic","")local bf=finale.FCString()bf.LuaString=be;if ba[be]or bd(be)then ba[be]=b4 and"user"or"system"end end end end;bb(true)bb(false)return ba end;function ay.get_smufl_metadata_file(bg)if not bg then bg=finale.FCFontInfo()bg:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local bh=function(bi,bg)local bj=bi..bg.Name.."/"..bg.Name..".json"return io.open(bj,"r")end;local bk=bh(b3(true),bg)if bk then return bk end;return bh(b3(false),bg)end;function ay.is_font_smufl_font(bg)if not bg then bg=finale.FCFontInfo()bg:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=ay.finale_version(27,1)then if nil~=bg.IsSMuFLFont then return bg.IsSMuFLFont end end;local bl=ay.get_smufl_metadata_file(bg)if nil~=bl then io.close(bl)return true end;return false end;function ay.simple_input(bm,bn)local bo=finale.FCString()bo.LuaString=""local A=finale.FCString()local bp=160;function format_ctrl(bq,br,bs,bt)bq:SetHeight(br)bq:SetWidth(bs)A.LuaString=bt;bq:SetText(A)end;title_width=string.len(bm)*6+54;if title_width>bp then bp=title_width end;text_width=string.len(bn)*6;if text_width>bp then bp=text_width end;A.LuaString=bm;local z=finale.FCCustomLuaWindow()z:SetTitle(A)local bu=z:CreateStatic(0,0)format_ctrl(bu,16,bp,bn)local bv=z:CreateEdit(0,20)format_ctrl(bv,20,bp,"")z:CreateOkButton()z:CreateCancelButton()function callback(bq)end;z:RegisterHandleCommand(callback)if z:ExecuteModal(nil)==finale.EXECMODAL_OK then bo.LuaString=bv:GetText(bo)return bo.LuaString end end;function ay.is_finale_object(bw)return bw and type(bw)=="userdata"and bw.ClassName and bw.GetClassID and true or false end;function ay.system_indent_set_to_prefs(aV,b1)b1=b1 or ay.get_page_format_prefs()local bx=finale.FCMeasure()local by=aV.FirstMeasure==1;if not by and bx:Load(aV.FirstMeasure)then if bx.ShowFullNames then by=true end end;if by and b1.UseFirstSystemMargins then aV.LeftMargin=b1.FirstSystemLeft else aV.LeftMargin=b1.SystemLeft end;return aV:Save()end;function ay.calc_script_name(bz)local bA=finale.FCString()if finenv.RunningLuaFilePath then bA.LuaString=finenv.RunningLuaFilePath()else bA:SetRunningLuaFilePath()end;local bB=finale.FCString()bA:SplitToPathAndFile(nil,bB)local aC=bB.LuaString;if not bz then aC=aC:match("(.+)%..+")if not aC or aC==""then aC=bB.LuaString end end;return aC end;return ay end)c("library.clef",function(require,n,c,d)local ay={}function ay.finale_version(az,aA,aB)local aC=bit32.bor(bit32.lshift(math.floor(az),24),bit32.lshift(math.floor(aA),20))if aB then aC=bit32.bor(aC,math.floor(aB))end;return aC end;function ay.group_overlaps_region(aD,w)if w:IsFullDocumentSpan()then return true end;local aE=false;local aF=finale.FCSystemStaves()aF:LoadAllForRegion(w)for aG in each(aF)do if aD:ContainsStaff(aG:GetStaff())then aE=true;break end end;if not aE then return false end;if aD.StartMeasure>w.EndMeasure or aD.EndMeasure<w.StartMeasure then return false end;return true end;function ay.group_is_contained_in_region(aD,w)if not w:IsStaffIncluded(aD.StartStaff)then return false end;if not w:IsStaffIncluded(aD.EndStaff)then return false end;return true end;function ay.staff_group_is_multistaff_instrument(aD)local aH=finale.FCMultiStaffInstruments()aH:LoadAll()for aI in each(aH)do if aI:ContainsStaff(aD.StartStaff)and aI.GroupID==aD:GetItemID()then return true end end;return false end;function ay.get_selected_region_or_whole_doc()local aJ=finenv.Region()if aJ:IsEmpty()then aJ:SetFullDocument()end;return aJ end;function ay.get_first_cell_on_or_after_page(aK)local aL=aK;local aM=finale.FCPage()local aN=false;while aM:Load(aL)do if aM:GetFirstSystem()>0 then aN=true;break end;aL=aL+1 end;if aN then local aO=finale.FCStaffSystem()aO:Load(aM:GetFirstSystem())return finale.FCCell(aO.FirstMeasure,aO.TopStaff)end;local aP=finale.FCMusicRegion()aP:SetFullDocument()return finale.FCCell(aP.EndMeasure,aP.EndStaff)end;function ay.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local aQ=finale.FCMusicRegion()aQ:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),aQ.StartStaff)end;return ay.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function ay.get_top_left_selected_or_visible_cell()local aJ=finenv.Region()if not aJ:IsEmpty()then return finale.FCCell(aJ.StartMeasure,aJ.StartStaff)end;return ay.get_top_left_visible_cell()end;function ay.is_default_measure_number_visible_on_cell(aR,aS,aT,aU)local C=finale.FCCurrentStaffSpec()if not C:LoadForCell(aS,0)then return false end;if aR:GetShowOnTopStaff()and aS.Staff==aT.TopStaff then return true end;if aR:GetShowOnBottomStaff()and aS.Staff==aT:CalcBottomStaff()then return true end;if C.ShowMeasureNumbers then return not aR:GetExcludeOtherStaves(aU)end;return false end;function ay.is_default_number_visible_and_left_aligned(aR,aS,aV,aU,aW)if aR.UseScoreInfoForParts then aU=false end;if aW and aR:GetShowOnMultiMeasureRests(aU)then if finale.MNALIGN_LEFT~=aR:GetMultiMeasureAlignment(aU)then return false end elseif aS.Measure==aV.FirstMeasure then if not aR:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=aR:GetStartAlignment(aU)then return false end else if not aR:GetShowMultiples(aU)then return false end;if finale.MNALIGN_LEFT~=aR:GetMultipleAlignment(aU)then return false end end;return ay.is_default_measure_number_visible_on_cell(aR,aS,aV,aU)end;function ay.update_layout(aX,aY)aX=aX or 1;aY=aY or false;local aZ=finale.FCPage()if aZ:Load(aX)then aZ:UpdateLayout(aY)end end;function ay.get_current_part()local a_=finale.FCParts()a_:LoadAll()return a_:GetCurrent()end;function ay.get_page_format_prefs()local b0=ay.get_current_part()local b1=finale.FCPageFormatPrefs()local b2=false;if b0:IsScore()then b2=b1:LoadScore()else b2=b1:LoadParts()end;return b1,b2 end;local b3=function(b4)local b5=finenv.UI():IsOnWindows()local b6=function(b7,b8)if finenv.UI():IsOnWindows()then return b7 and os.getenv(b7)or""else return b8 and os.getenv(b8)or""end end;local b9=b4 and b6("LOCALAPPDATA","HOME")or b6("COMMONPROGRAMFILES")if not b5 then b9=b9 .."/Library/Application Support"end;b9=b9 .."/SMuFL/Fonts/"return b9 end;function ay.get_smufl_font_list()local ba={}local bb=function(b4)local b9=b3(b4)local bc=function()if finenv.UI():IsOnWindows()then return io.popen('dir "'..b9 ..'" /b /ad')else return io.popen('ls "'..b9 ..'"')end end;local bd=function(be)local bf=finale.FCString()bf.LuaString=be;return finenv.UI():IsFontAvailable(bf)end;for be in bc():lines()do if not be:find("%.")then be=be:gsub(" Bold","")be=be:gsub(" Italic","")local bf=finale.FCString()bf.LuaString=be;if ba[be]or bd(be)then ba[be]=b4 and"user"or"system"end end end end;bb(true)bb(false)return ba end;function ay.get_smufl_metadata_file(bg)if not bg then bg=finale.FCFontInfo()bg:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local bh=function(bi,bg)local bj=bi..bg.Name.."/"..bg.Name..".json"return io.open(bj,"r")end;local bk=bh(b3(true),bg)if bk then return bk end;return bh(b3(false),bg)end;function ay.is_font_smufl_font(bg)if not bg then bg=finale.FCFontInfo()bg:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=ay.finale_version(27,1)then if nil~=bg.IsSMuFLFont then return bg.IsSMuFLFont end end;local bl=ay.get_smufl_metadata_file(bg)if nil~=bl then io.close(bl)return true end;return false end;function ay.simple_input(bm,bn)local bo=finale.FCString()bo.LuaString=""local A=finale.FCString()local bp=160;function format_ctrl(bq,br,bs,bt)bq:SetHeight(br)bq:SetWidth(bs)A.LuaString=bt;bq:SetText(A)end;title_width=string.len(bm)*6+54;if title_width>bp then bp=title_width end;text_width=string.len(bn)*6;if text_width>bp then bp=text_width end;A.LuaString=bm;local z=finale.FCCustomLuaWindow()z:SetTitle(A)local bu=z:CreateStatic(0,0)format_ctrl(bu,16,bp,bn)local bv=z:CreateEdit(0,20)format_ctrl(bv,20,bp,"")z:CreateOkButton()z:CreateCancelButton()function callback(bq)end;z:RegisterHandleCommand(callback)if z:ExecuteModal(nil)==finale.EXECMODAL_OK then bo.LuaString=bv:GetText(bo)return bo.LuaString end end;function ay.is_finale_object(bw)return bw and type(bw)=="userdata"and bw.ClassName and bw.GetClassID and true or false end;function ay.system_indent_set_to_prefs(aV,b1)b1=b1 or ay.get_page_format_prefs()local bx=finale.FCMeasure()local by=aV.FirstMeasure==1;if not by and bx:Load(aV.FirstMeasure)then if bx.ShowFullNames then by=true end end;if by and b1.UseFirstSystemMargins then aV.LeftMargin=b1.FirstSystemLeft else aV.LeftMargin=b1.SystemLeft end;return aV:Save()end;function ay.calc_script_name(bz)local bA=finale.FCString()if finenv.RunningLuaFilePath then bA.LuaString=finenv.RunningLuaFilePath()else bA:SetRunningLuaFilePath()end;local bB=finale.FCString()bA:SplitToPathAndFile(nil,bB)local aC=bB.LuaString;if not bz then aC=aC:match("(.+)%..+")if not aC or aC==""then aC=bB.LuaString end end;return aC end;return ay end)c("library.configuration",function(require,n,c,d)local ay={}function ay.finale_version(az,aA,aB)local aC=bit32.bor(bit32.lshift(math.floor(az),24),bit32.lshift(math.floor(aA),20))if aB then aC=bit32.bor(aC,math.floor(aB))end;return aC end;function ay.group_overlaps_region(aD,w)if w:IsFullDocumentSpan()then return true end;local aE=false;local aF=finale.FCSystemStaves()aF:LoadAllForRegion(w)for aG in each(aF)do if aD:ContainsStaff(aG:GetStaff())then aE=true;break end end;if not aE then return false end;if aD.StartMeasure>w.EndMeasure or aD.EndMeasure<w.StartMeasure then return false end;return true end;function ay.group_is_contained_in_region(aD,w)if not w:IsStaffIncluded(aD.StartStaff)then return false end;if not w:IsStaffIncluded(aD.EndStaff)then return false end;return true end;function ay.staff_group_is_multistaff_instrument(aD)local aH=finale.FCMultiStaffInstruments()aH:LoadAll()for aI in each(aH)do if aI:ContainsStaff(aD.StartStaff)and aI.GroupID==aD:GetItemID()then return true end end;return false end;function ay.get_selected_region_or_whole_doc()local aJ=finenv.Region()if aJ:IsEmpty()then aJ:SetFullDocument()end;return aJ end;function ay.get_first_cell_on_or_after_page(aK)local aL=aK;local aM=finale.FCPage()local aN=false;while aM:Load(aL)do if aM:GetFirstSystem()>0 then aN=true;break end;aL=aL+1 end;if aN then local aO=finale.FCStaffSystem()aO:Load(aM:GetFirstSystem())return finale.FCCell(aO.FirstMeasure,aO.TopStaff)end;local aP=finale.FCMusicRegion()aP:SetFullDocument()return finale.FCCell(aP.EndMeasure,aP.EndStaff)end;function ay.get_top_left_visible_cell()if not finenv.UI():IsPageView()then local aQ=finale.FCMusicRegion()aQ:SetFullDocument()return finale.FCCell(finenv.UI():GetCurrentMeasure(),aQ.StartStaff)end;return ay.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())end;function ay.get_top_left_selected_or_visible_cell()local aJ=finenv.Region()if not aJ:IsEmpty()then return finale.FCCell(aJ.StartMeasure,aJ.StartStaff)end;return ay.get_top_left_visible_cell()end;function ay.is_default_measure_number_visible_on_cell(aR,aS,aT,aU)local C=finale.FCCurrentStaffSpec()if not C:LoadForCell(aS,0)then return false end;if aR:GetShowOnTopStaff()and aS.Staff==aT.TopStaff then return true end;if aR:GetShowOnBottomStaff()and aS.Staff==aT:CalcBottomStaff()then return true end;if C.ShowMeasureNumbers then return not aR:GetExcludeOtherStaves(aU)end;return false end;function ay.is_default_number_visible_and_left_aligned(aR,aS,aV,aU,aW)if aR.UseScoreInfoForParts then aU=false end;if aW and aR:GetShowOnMultiMeasureRests(aU)then if finale.MNALIGN_LEFT~=aR:GetMultiMeasureAlignment(aU)then return false end elseif aS.Measure==aV.FirstMeasure then if not aR:GetShowOnSystemStart()then return false end;if finale.MNALIGN_LEFT~=aR:GetStartAlignment(aU)then return false end else if not aR:GetShowMultiples(aU)then return false end;if finale.MNALIGN_LEFT~=aR:GetMultipleAlignment(aU)then return false end end;return ay.is_default_measure_number_visible_on_cell(aR,aS,aV,aU)end;function ay.update_layout(aX,aY)aX=aX or 1;aY=aY or false;local aZ=finale.FCPage()if aZ:Load(aX)then aZ:UpdateLayout(aY)end end;function ay.get_current_part()local a_=finale.FCParts()a_:LoadAll()return a_:GetCurrent()end;function ay.get_page_format_prefs()local b0=ay.get_current_part()local b1=finale.FCPageFormatPrefs()local b2=false;if b0:IsScore()then b2=b1:LoadScore()else b2=b1:LoadParts()end;return b1,b2 end;local b3=function(b4)local b5=finenv.UI():IsOnWindows()local b6=function(b7,b8)if finenv.UI():IsOnWindows()then return b7 and os.getenv(b7)or""else return b8 and os.getenv(b8)or""end end;local b9=b4 and b6("LOCALAPPDATA","HOME")or b6("COMMONPROGRAMFILES")if not b5 then b9=b9 .."/Library/Application Support"end;b9=b9 .."/SMuFL/Fonts/"return b9 end;function ay.get_smufl_font_list()local ba={}local bb=function(b4)local b9=b3(b4)local bc=function()if finenv.UI():IsOnWindows()then return io.popen('dir "'..b9 ..'" /b /ad')else return io.popen('ls "'..b9 ..'"')end end;local bd=function(be)local bf=finale.FCString()bf.LuaString=be;return finenv.UI():IsFontAvailable(bf)end;for be in bc():lines()do if not be:find("%.")then be=be:gsub(" Bold","")be=be:gsub(" Italic","")local bf=finale.FCString()bf.LuaString=be;if ba[be]or bd(be)then ba[be]=b4 and"user"or"system"end end end end;bb(true)bb(false)return ba end;function ay.get_smufl_metadata_file(bg)if not bg then bg=finale.FCFontInfo()bg:LoadFontPrefs(finale.FONTPREF_MUSIC)end;local bh=function(bi,bg)local bj=bi..bg.Name.."/"..bg.Name..".json"return io.open(bj,"r")end;local bk=bh(b3(true),bg)if bk then return bk end;return bh(b3(false),bg)end;function ay.is_font_smufl_font(bg)if not bg then bg=finale.FCFontInfo()bg:LoadFontPrefs(finale.FONTPREF_MUSIC)end;if finenv.RawFinaleVersion>=ay.finale_version(27,1)then if nil~=bg.IsSMuFLFont then return bg.IsSMuFLFont end end;local bl=ay.get_smufl_metadata_file(bg)if nil~=bl then io.close(bl)return true end;return false end;function ay.simple_input(bm,bn)local bo=finale.FCString()bo.LuaString=""local A=finale.FCString()local bp=160;function format_ctrl(bq,br,bs,bt)bq:SetHeight(br)bq:SetWidth(bs)A.LuaString=bt;bq:SetText(A)end;title_width=string.len(bm)*6+54;if title_width>bp then bp=title_width end;text_width=string.len(bn)*6;if text_width>bp then bp=text_width end;A.LuaString=bm;local z=finale.FCCustomLuaWindow()z:SetTitle(A)local bu=z:CreateStatic(0,0)format_ctrl(bu,16,bp,bn)local bv=z:CreateEdit(0,20)format_ctrl(bv,20,bp,"")z:CreateOkButton()z:CreateCancelButton()function callback(bq)end;z:RegisterHandleCommand(callback)if z:ExecuteModal(nil)==finale.EXECMODAL_OK then bo.LuaString=bv:GetText(bo)return bo.LuaString end end;function ay.is_finale_object(bw)return bw and type(bw)=="userdata"and bw.ClassName and bw.GetClassID and true or false end;function ay.system_indent_set_to_prefs(aV,b1)b1=b1 or ay.get_page_format_prefs()local bx=finale.FCMeasure()local by=aV.FirstMeasure==1;if not by and bx:Load(aV.FirstMeasure)then if bx.ShowFullNames then by=true end end;if by and b1.UseFirstSystemMargins then aV.LeftMargin=b1.FirstSystemLeft else aV.LeftMargin=b1.SystemLeft end;return aV:Save()end;function ay.calc_script_name(bz)local bA=finale.FCString()if finenv.RunningLuaFilePath then bA.LuaString=finenv.RunningLuaFilePath()else bA:SetRunningLuaFilePath()end;local bB=finale.FCString()bA:SplitToPathAndFile(nil,bB)local aC=bB.LuaString;if not bz then aC=aC:match("(.+)%..+")if not aC or aC==""then aC=bB.LuaString end end;return aC end;return ay end)return a("__root")