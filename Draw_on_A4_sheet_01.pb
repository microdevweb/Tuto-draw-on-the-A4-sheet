;************************************************************************************************************************
; Author : MicrodevWeb
; Project Name : Tuto Draw on A4 sheet
; File Name : Draw_on_A4_sheet_01.pb
; Description : Mise ne place et fonction de zoom
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
;}
;-* procedures declaration
Declare OpenMainForm()
Declare GetSizeInPxl()
Declare RepositionOfGadget()
Declare Exit()
Declare myCanvasEvent()
Declare Draw()
Declare ManageZoom()
;}
;-* procedures
Procedure OpenMainForm()
    Protected Title.s="Draw on the A4 sheet Part 1"
    Protected Flag=#PB_Window_SystemMenu|#PB_Window_Maximize
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
    Select EventType()
        Case #PB_EventType_MouseWheel ; La molette de la souris
            ManageZoom()
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
;}

OpenMainForm()

;-* Main loop
Repeat:WaitWindowEvent():ForEver
;}
; IDE Options = PureBasic 5.50 beta 1 (Windows - x64)
; CursorPosition = 90
; Folding = 0M--
; EnableXP