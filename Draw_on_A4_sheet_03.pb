;************************************************************************************************************************
; Author : MicrodevWeb
; Project Name : Tuto Draw on A4 sheet
; File Name : Draw_on_A4_sheet_03.pb
; Description : Sélection et déplacement des rectangles
;************************************************************************************************************************
EnableExplicit
;-* Global variables and constants
#MainForm=0
#MainArea=0
#MainCanvas=1
; Format A4 en Mm
Global SheetWidh=210,SheetHeight=297
; Format A4 en pixels et suivant le facteur de zoom
Global SheetPxlWidht,SheetPxlHeight
; Facteur de zoom
Global ZoomFactor.d=0.5,MinimumZoom=0.25,MaximumZoom=4
; Couleur de fond au format RGBA pour vector RGB ne fonctionne pas
Global BgColor.q=RGBA(255, 255, 255, 255)
; Positions de la souris
Global gMouseX,gMouseY,OldX,OldY
; Les rectangles
Structure pos
    X.i
    Y.i
    W.i
    H.i
EndStructure
Global NewList myBox.pos()
Global OldBox.pos
Global BoxColor=RGBA(178, 58, 238, 255)
; Le rectangle qui sera sélectionné au départ -1 car aucun rectangle n'est sélectionné
Global *CurrentBox=-1
; Le rectangle survolé au départ -1 car aucun rectangle n'est survolé
Global *BoxOver=-1
; L'action, si pas sur un rectangle et clique de la souris on ajoute 
; si sur un rectangle on le sélectionne
Enumeration Action
    #Add
    #Edit
EndEnumeration
Global CurrentAction.i=-1 ; -1 pas d'action
 ; Les poignées
Enumeration HandleType
    #Lu ; gauche au dessus
    #Lm ; gauche au millieu
    #Ld ; Gauche en bas
    #Ru ; droite au dessus
    #Rm ; droite au millieu
    #Rd ; droite en bas
    #Um ; Haut au millieu
    #Dm ; Bas au millieu
EndEnumeration
Structure Handle Extends pos
    Type.i
EndStructure
Global NewList myHandles.Handle()
; La taille de la poignée Attention en Mm
Global HandleSize=4
Global HandleColor.q=RGBA(139, 136, 120, 255)
Global HandleColorOver.q=RGBA(0, 255, 0, 255)
Global *HandleOver=-1
;}
;-* procedures declaration
Declare OpenMainForm()
Declare GetSizeInPxl()
Declare RepositionOfGadget()
Declare Exit()
Declare myCanvasEvent()
Declare Draw()
Declare ManageZoom()
Declare GetMousePosition()
Declare ManageNewBox()
Declare WhereIsMouse()
Declare DrawBox()
Declare AddHandles()
Declare DrawHandles()
Declare IsOverHandle()
Declare CopyPosition()
Declare ResizeBox()
Declare MoveHandles()
Declare EventResize()
;}
;-* procedures
Procedure OpenMainForm()
    Protected Title.s="Draw on the A4 sheet Part 1"
    Protected Flag=#PB_Window_SystemMenu|#PB_Window_MaximizeGadget|#PB_Window_MinimizeGadget
    Flag|#PB_Window_ScreenCentered|#PB_Window_SizeGadget
    Protected WF,HF
    ; Ouverture de la fenêtre
    OpenWindow(#MainForm,0,0,800,600,Title,Flag)
    ; Relève la taille de la fenêtre
    WF=WindowWidth(#MainForm)
    HF=WindowHeight(#MainForm)
    ; Création d'un SrollArea
    ScrollAreaGadget(#MainArea,0,0,WF,HF,WF-5,HF-5,50)
    ; Création du canvas avec des dimentions quelconques
    CanvasGadget(#MainCanvas,0,0,100,100,#PB_Canvas_Keyboard)
    ; Fermeture du srollArea
    CloseGadgetList()
    ; Redimention et positionement du canvas
    RepositionOfGadget()
    ; Dessin du canvas
    Draw()
    ; Mise en place des callback
    ; Pour la sortie
    BindEvent(#PB_Event_CloseWindow,@Exit(),#MainForm)
    ; Pour la gestion du canvas
    BindGadgetEvent(#MainCanvas,@myCanvasEvent())
    ; Pour le resize de la fenêtre
    BindEvent(#PB_Event_SizeWindow,@EventResize(),#MainForm)
EndProcedure
Procedure GetSizeInPxl()
    ; Important ici on choisi l'unité en pixel
    StartVectorDrawing(CanvasVectorOutput(#MainCanvas,#PB_Unit_Millimeter))
    ; On applique le zoom
    ScaleCoordinates(ZoomFactor,ZoomFactor,#PB_Coordinate_User)
    ; On convertis maintenant les dimentions en pixels
    SheetPxlWidht=ConvertCoordinateX(SheetWidh,0,#PB_Coordinate_User,#PB_Coordinate_Device)
    SheetPxlHeight=ConvertCoordinateY(0,SheetHeight,#PB_Coordinate_User,#PB_Coordinate_Device)
    StopVectorDrawing()
EndProcedure
Procedure RepositionOfGadget()
    Protected X,Y
    ; Convertion de la taille en Pxl
    GetSizeInPxl()
    ; Si la largeur du canvas est plus petite que la largeur du srollArea on centre sur l'axe X
    If SheetPxlWidht<GadgetWidth(#MainArea)
        X=(GadgetWidth(#MainArea)/2)-(SheetPxlWidht/2)
    Else
        X=0
    EndIf
    ; Si la hauteur du canvas est plus petite que la hauteur du srollArea on centre sur l'axe Y
    If SheetPxlHeight<GadgetHeight(#MainArea)
        Y=(GadgetHeight(#MainArea)/2)-(SheetPxlHeight/2)
    Else
        Y=0
    EndIf
    ; On positionne est dimentionne le canvas
    ResizeGadget(#MainCanvas,X,Y,SheetPxlWidht,SheetPxlHeight)
    ;Redimentionne la zone interne du scrollArea
    If GadgetWidth(#MainCanvas)-5>GadgetWidth(#MainArea)
        SetGadgetAttribute(#MainArea,#PB_ScrollArea_InnerWidth,GadgetWidth(#MainCanvas)+50)
    Else
        SetGadgetAttribute(#MainArea,#PB_ScrollArea_InnerWidth,GadgetWidth(#MainArea)-5)
    EndIf
    If GadgetHeight(#MainCanvas)-5>GadgetHeight(#MainArea)
        SetGadgetAttribute(#MainArea,#PB_ScrollArea_InnerHeight,GadgetHeight(#MainCanvas)+50)
    Else
        SetGadgetAttribute(#MainArea,#PB_ScrollArea_InnerHeight,GadgetHeight(#MainArea)-5)
    EndIf
EndProcedure
Procedure Exit()
    End
EndProcedure
Procedure myCanvasEvent()
    Static ClicOn.b=#False
    Static BoxAdded.b=#False
    ; Relève la position de la souris en mm
    GetMousePosition()
    Select EventType()
        Case #PB_EventType_MouseWheel ; La molette de la souris
            ManageZoom()
        Case #PB_EventType_MouseMove
            If Not ClicOn
                If WhereIsMouse() 
                    ; Si pas de poignée survolée et le que le rectangle est sélectionné
                    If *HandleOver=-1 And *CurrentBox>-1 And *CurrentBox=*BoxOver
                        SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_Arrows)
                    EndIf
                    ProcedureReturn 
                EndIf
                ; Si pas de rectangle sélectionné je change le curseur de la souris
                SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_Default)
                ProcedureReturn 
            EndIf
            ; Le bt de la souris est enfoncé
            Select CurrentAction
                Case #Add
                    ; Le box n'est pas encore ajouté on l'ajoute
                    If Not BoxAdded
                        AddElement(myBox())
                        BoxAdded=#True
                    EndIf
                    ManageNewBox()
                Case #Edit
                   ResizeBox()
            EndSelect
        Case #PB_EventType_LeftButtonDown
            ; On mémorise la position de la souris lord du premier clique
            If Not ClicOn
                OldX=gMouseX
                OldY=gMouseY
                ; On copie la position du rectangle
                CopyPosition()
                ; Si aucun rectangle n'est survolé on passe en mode ajout
                If *BoxOver=-1 And *HandleOver=-1
                    CurrentAction=#Add
                    ;Le box n'est pas encore ajouté
                    BoxAdded=#False
                    ; On supprime une éventuelle sélection si pas sur une poignée
                    If *HandleOver=-1
                        *CurrentBox=-1
                        ClearList(myHandles())
                        Draw()
                    EndIf
                Else
                    ; Si pas encore d'action
                    If *BoxOver<>*CurrentBox
                        ; Survole un rectangle je passe en mode édition
                        CurrentAction=#Edit
                        *CurrentBox=*BoxOver
                        ; J'ajoute les poignées
                        AddHandles()
                        Draw()
                    EndIf
                EndIf
            EndIf
            ClicOn=#True
        Case #PB_EventType_LeftButtonUp
            ; plus d'action
            If *CurrentBox=-1
                CurrentAction=-1
            EndIf
            ClicOn=#False
    EndSelect
EndProcedure
Procedure Draw()
    ; Important ici on choisi l'unité en pixel
    StartVectorDrawing(CanvasVectorOutput(#MainCanvas,#PB_Unit_Millimeter))
    ; On applique le zoom
    ScaleCoordinates(ZoomFactor,ZoomFactor,#PB_Coordinate_User)
    ; J'efface le canvas avec la couleur de fond
    VectorSourceColor(BgColor)
    FillVectorOutput()
    DrawBox()
    DrawHandles()
    StopVectorDrawing()
EndProcedure
Procedure ManageZoom()
    Protected Delta
    ; Si la touche control n'est pas enfoncée je sort
    If GetGadgetAttribute(#MainCanvas,#PB_Canvas_Modifiers)<>#PB_Canvas_Control
        ProcedureReturn 
    EndIf
    Delta=GetGadgetAttribute(#MainCanvas,#PB_Canvas_WheelDelta)
    If Delta<0 ;Molette vers le bas
        If ZoomFactor>MinimumZoom
            ZoomFactor-0.1
        EndIf
    Else
        If ZoomFactor<MaximumZoom
            ZoomFactor+0.1
        EndIf
    EndIf
    RepositionOfGadget()
    Draw()
EndProcedure
Procedure GetMousePosition()
    ; Important ici on choisi l'unité en pixel
    StartVectorDrawing(CanvasVectorOutput(#MainCanvas,#PB_Unit_Millimeter))
    ; On applique le zoom
    ScaleCoordinates(ZoomFactor,ZoomFactor,#PB_Coordinate_User)
    ; Conversion de la position de la souris en Mm
    gMouseX=ConvertCoordinateX(GetGadgetAttribute(#MainCanvas,#PB_Canvas_MouseX),0,#PB_Coordinate_Device,#PB_Coordinate_User)
    gMouseY=ConvertCoordinateY(0,GetGadgetAttribute(#MainCanvas,#PB_Canvas_MouseY),#PB_Coordinate_Device,#PB_Coordinate_User)
    StopVectorDrawing()
EndProcedure
Procedure WhereIsMouse()
    ; Au départ aucun rectangle n'est survolé
    *BoxOver=-1
    If IsOverHandle():ProcedureReturn #True:EndIf
    With myBox()
        ForEach myBox()
            If (gMouseX>=\X And gMouseX<=(\X+\W)) And (gMouseY>=\Y And gMouseY<=(\Y+\H))
                ; On mémorise l'adresse mémoire du rectangle
                *BoxOver=@myBox()
                ; On change le curseur de la souris
                SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_Hand)
                ; Un rectangle est survolé
                ProcedureReturn #True
            EndIf
        Next
    EndWith
    ; Aucun rectangle n'est survolé
    ProcedureReturn #False
EndProcedure
Procedure ManageNewBox()
    ; Le déplacement de la souris depuis le premier clique
    Protected DepX,DepY
    DepX=gMouseX-OldX
    DepY=gMouseY-OldY
    ; La taille minimum du rectangle est de 1mm
    If DepX<1 Or DepY<1
        ; On change le curseur de la souris
        SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_Denied)
        ProcedureReturn 
    EndIf
    With myBox()
        \X=OldX
        \Y=OldY
        \W=DepX
        \H=DepY
    EndWith
    ; On change le curseur de la souris
    SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_Cross)
    ; On dessine la feuille
    Draw()
EndProcedure
Procedure DrawBox()
    VectorSourceColor(BoxColor)
    ForEach myBox()
        With myBox()
            AddPathBox(\X,\Y,\W,\H)
        EndWith
    Next
    FillPath()
EndProcedure
Procedure AddHandles()
    Protected X,Y,W,H
    ; Efface les poignées
    ClearList(myHandles())
    ChangeCurrentElement(myBox(),*CurrentBox)
    With myBox()
        X=\X
        Y=\Y
        W=\W
        H=\H
    EndWith
    With myHandles()
        ; Gauche en haut
        AddElement(myHandles())
        \Type=#lu
        \X=X-(HandleSize/2)
        \Y=Y-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Gauche au millieu
        AddElement(myHandles())
        \Type=#lm
        \X=X-(HandleSize/2)
        \Y=(Y+(H/2))-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Gauche en bas
        AddElement(myHandles())
        \Type=#ld
        \X=X-(HandleSize/2)
        \Y=(Y+H)-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        
        ; Droite en haut
        AddElement(myHandles())
        \Type=#Ru
        \X=(X+W)-(HandleSize/2)
        \Y=Y-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Droite au millieu
        AddElement(myHandles())
        \Type=#Rm
        \X=(X+W)-(HandleSize/2)
        \Y=(Y+(H/2))-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Droite en bas
        AddElement(myHandles())
        \Type=#Rd
        \X=(X+W)-(HandleSize/2)
        \Y=(Y+H)-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        
        ; Haut au millieu
        AddElement(myHandles())
        \Type=#Um
        \X=(X+(W/2))-(HandleSize/2)
        \Y=Y-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        
        ; Bas au millieu
        AddElement(myHandles())
        \Type=#Dm
        \X=(X+(W/2))-(HandleSize/2)
        \Y=(Y+H)-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
    EndWith
EndProcedure
Procedure DrawHandles()
    ForEach myHandles()
        With myHandles()
            ; Si la poignée est survolée
            If @myHandles()=*HandleOver
                VectorSourceColor(HandleColorOver)
            Else
                VectorSourceColor(HandleColor)
            EndIf
            AddPathBox(\X,\Y,\W,\H)
            FillPath()
        EndWith
    Next
EndProcedure
Procedure IsOverHandle()
    With myHandles()
        ForEach myHandles()
            If (gMouseX>=\X And gMouseX<=(\X+\W)) And (gMouseY>=\Y And gMouseY<=(\Y+\H))
                *HandleOver=@myHandles()
                ; Comme on sort de whereismouse on mémorise le Box survolé comme celui sélectionné
                *BoxOver=*CurrentBox
                ; Change le curseur de la souris
                Select \Type
                    Case #Lu,#Rd
                        SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_LeftUpRightDown)
                    Case #Lm,#RM
                        SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_LeftRight)
                    Case #Ld,#Ru
                        SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_LeftDownRightUp)
                    Case #Um,#Dm
                        SetGadgetAttribute(#MainCanvas,#PB_Canvas_Cursor,#PB_Cursor_UpDown)
                EndSelect
                ; dessine la feuille
                Draw()
                ProcedureReturn #True
            EndIf
        Next
    EndWith
    ; Si une poignée était survolée avant on dessine pour effacé le survol
    If *HandleOver>-1
        *HandleOver=-1
        Draw()
    EndIf
    *HandleOver=-1
    ProcedureReturn #False
EndProcedure
Procedure CopyPosition()
    If *CurrentBox=-1:ProcedureReturn :EndIf
    ChangeCurrentElement(myBox(),*CurrentBox)
    With myBox()
        OldBox\X=\X
        OldBox\Y=\Y
        OldBox\W=\W
        OldBox\H=\H
    EndWith
EndProcedure
Procedure ResizeBox()
    ; Le déplacement de la souris depuis le premier clique
    Protected DepX,DepY
    DepX=gMouseX-OldX
    DepY=gMouseY-OldY
   ChangeCurrentElement(myBox(),*CurrentBox)
    With myBox()
         ;Si pas sur un poignée om bouge le rectangle
        If *HandleOver=-1
            \X=OldBox\X+DepX
            \Y=OldBox\Y+DepY
        Else
            ChangeCurrentElement(myHandles(),*HandleOver)
            Select myHandles()\Type
                Case #Lu
                    If OldBox\W-DepX<1 Or OldBox\H-DepY<1
                        ProcedureReturn 
                    EndIf
                    \W=OldBox\W-DepX
                    \X=OldBox\X+DepX
                    \Y=OldBox\Y+DepY
                    \H=OldBox\H-DepY
                Case #Lm
                    If OldBox\W-DepX<1 
                        ProcedureReturn 
                    EndIf
                    \W=OldBox\W-DepX
                    \X=OldBox\X+DepX
                Case #Ld
                    If OldBox\W-DepX<1 Or OldBox\H+DepY<1
                        ProcedureReturn 
                    EndIf
                    \W=OldBox\W-DepX
                    \X=OldBox\X+DepX
                    \H=OldBox\H+DepY
                Case #Ru
                    If OldBox\W+DepX<1 Or OldBox\H-DepY<1
                        ProcedureReturn 
                    EndIf
                    \W=OldBox\W+DepX
                    \Y=OldBox\Y+DepY
                    \H=OldBox\H-DepY
                Case #Rm
                    If OldBox\W+DepX<1 
                        ProcedureReturn 
                    EndIf
                    \W=OldBox\W+DepX
                Case #Rd
                     If OldBox\W+DepX<1 Or OldBox\H+DepY<1
                        ProcedureReturn 
                    EndIf
                    \W=OldBox\W+DepX
                    \H=OldBox\H+DepY
                Case #Um
                    If OldBox\H-DepY<1
                        ProcedureReturn 
                    EndIf
                    \Y=OldBox\Y+DepY
                    \H=OldBox\H-DepY
                Case #Dm
                   If OldBox\H+DepY<1
                        ProcedureReturn 
                    EndIf
                    \H=OldBox\H+DepY  
            EndSelect
        EndIf
        MoveHandles()
        Draw()
    EndWith
EndProcedure
Procedure MoveHandles()
     Protected X,Y,W,H
    With myBox()
        X=\X
        Y=\Y
        W=\W
        H=\H
    EndWith
    With myHandles()
        ; Gauche en haut
        SelectElement(myHandles(),0)
        \X=X-(HandleSize/2)
        \Y=Y-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Gauche au millieu
        SelectElement(myHandles(),1)
        \X=X-(HandleSize/2)
        \Y=(Y+(H/2))-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Gauche en bas
        SelectElement(myHandles(),2)
        \X=X-(HandleSize/2)
        \Y=(Y+H)-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        
        ; Droite en haut
        SelectElement(myHandles(),3)
        \X=(X+W)-(HandleSize/2)
        \Y=Y-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Droite au millieu
        SelectElement(myHandles(),4)
        \X=(X+W)-(HandleSize/2)
        \Y=(Y+(H/2))-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        ; Droite en bas
        SelectElement(myHandles(),5)
        \X=(X+W)-(HandleSize/2)
        \Y=(Y+H)-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        
        ; Haut au millieu
        SelectElement(myHandles(),6)
        \X=(X+(W/2))-(HandleSize/2)
        \Y=Y-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
        
        ; Bas au millieu
        SelectElement(myHandles(),7)
        \X=(X+(W/2))-(HandleSize/2)
        \Y=(Y+H)-(HandleSize/2)
        \W=HandleSize
        \H=HandleSize
    EndWith
EndProcedure
Procedure EventResize()
    Protected WF,HF
    ; Relève la taille de la fenêtre
    WF=WindowWidth(#MainForm)
    HF=WindowHeight(#MainForm)
    ResizeGadget(#MainArea,#PB_Ignore,#PB_Ignore,WF,HF)
    RepositionOfGadget()
    Draw()
EndProcedure
;}

OpenMainForm()

;-* Main loop
Repeat:WaitWindowEvent():ForEver
;}
; IDE Options = PureBasic 5.50 beta 1 (Windows - x64)
; CursorPosition = 509
; FirstLine = 66
; Folding = ABAAAIAAe-5
; EnableXP