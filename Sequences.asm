//==========Sequences==========

//Blank template.
;sequence@:
;.dw ((@/1.024)-1) ;delay time between each frame in miliseconds
;.dw 0x@ ;frame count
;.dw frame@
;...

sequence0:
.dw ((500/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x1B ;frame count
.dw frameNULL
.dw frameA
.dw frameB
.dw frameC
.dw frameD
.dw frameE
.dw frameF
.dw frameG
.dw frameH
.dw frameI
.dw frameJ
.dw frameK
.dw frameL
.dw frameM
.dw frameN
.dw frameO
.dw frameP
.dw frameQ
.dw frameR
.dw frameS
.dw frameT
.dw frameU
.dw frameV
.dw frameW
.dw frameX
.dw frameY
.dw frameZ

sequence1:
.dw ((500/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x0D ;frame count
.dw frameNULL
.dw frameH
.dw frameO
.dw frameW
.dw frameNULL
.dw frameA
.dw frameR
.dw frameE
.dw frameNULL
.dw frameY
.dw frameO
.dw frameU
.dw frameINTERROGATION

sequence2:
.dw ((1000/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x02 ;frame count
.dw frameNULL
.dw frame2

sequence3:
.dw ((1000/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x02 ;frame count
.dw frameNULL
.dw frame3

sequence4:
.dw ((1000/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x02 ;frame count
.dw frameNULL
.dw frame4

sequence5:
.dw ((1000/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x02 ;frame count
.dw frameNULL
.dw frame5

sequence6:
.dw ((500/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x1F ;frame count
.dw frameNULL
.dw frameT
.dw frameH
.dw frameI
.dw frameS
.dw frameNULL
.dw frameW
.dw frameA
.dw frameS
.dw frameNULL
.dw frameD
.dw frameE
.dw frameV
.dw frameE
.dw frameL
.dw frameO
.dw frameP
.dw frameE
.dw frameD
.dw frameNULL
.dw frameB
.dw frameY
.dw frameNULL
.dw frameG
.dw frameA
.dw frameR
.dw frameR
.dw frameE
.dw frameT
.dw frameT
.dw framePERIOD

sequence7:
.dw ((1000/1.024)-1) ;delay time between each frame in miliseconds
.dw 0x02 ;frame count
.dw frameNULL
.dw frame7

