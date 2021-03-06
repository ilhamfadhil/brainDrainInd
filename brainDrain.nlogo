breed [students student]
breed [pros pro]
breed [native-inas native-ina]
breed [native-abrs native-abr]

extensions [nw]

globals [
  ina-patches  ;; domestics patches
  abr-patches  ;; abroad patches
  year         ;; to mark time of year
  agg-gdp      ;; agregate gdp
  total-ina-hs ;; aggregate ina-hs workers
]

undirected-link-breed [friendships friendship]

native-abrs-own[
  tolerance-abr
]
native-inas-own[
  tolerance-ina
]
students-own [
  age          ;; student's age
  college      ;; college status
  status       ;; living location of students
  capital      ;; financial status
  study-time   ;; length of study
  degree       ;; title degree
  knowledge    ;; knowledge during study period
  skill        ;; skill after become hs worker
  married?     ;; marriage status
  return       ;; return decision
]

to setup

  clear-all
  system-dynamics-setup
  set-default-shape turtles "person"

  set ina-patches patches with [pxcor > 0] ;; create domestic space
  ask ina-patches [set pcolor 19]

  set abr-patches patches with [pxcor < 0] ;; create abroad space
  ask abr-patches [set pcolor 99]

  create-native
  create-student
  native-create-link
  create-pro

  set year 0
  reset-ticks

end

to go

  system-dynamics-go
  system-dynamics-do-plot

  scholarship
  study
  emigrate
  aging
  die-naturally
  new-cohort
  become-hs
  get-married
  hs-return
  pro-create-link
  pro-move
  link-die
  set-sysdyn
  year-tick


  tick

end

to create-student

  create-students 100 [
    move-to-empty-one-of ina-patches
    set age int random-normal 17 1
    set color green
    set college FALSE
    set status "INA"
    set capital random-normal 100 20
    set degree "High School"
    set knowledge []
    set skill 0
    set married? 0
  ]
  ask students [
    create-friendships-with other n-of (count students in-radius 5) students in-radius 5
  ]

end

to create-native

  create-native-inas 25 [
    move-to-empty-one-of ina-patches
    set color orange
    set tolerance-ina random-float tolerance-level-native-ina
  ]
  create-native-abrs 50 [ ;; assuming more foreigner abroad
    move-to-empty-one-of abr-patches
    set color orange
    set tolerance-abr random-float tolerance-level-native-abr
  ]

end

to create-pro

  create-pros 10 [
    move-to-empty-one-of ina-patches
    set color brown
  ]
  create-pros 10 [
    move-to-empty-one-of abr-patches
    set color brown
  ]

end

to native-create-link

  if ticks mod 52 = 0 [ ;; native create links once a year
    ask native-inas [
      let num n-recruit self ina-patches tolerance-ina
      create-friendships-with other n-of (num) turtles-on ina-patches in-radius 5
    ]
    ask native-abrs [
      let num n-recruit self abr-patches tolerance-abr
      create-friendships-with other n-of (num) turtles-on abr-patches in-radius 5
    ]
  ]

end

to pro-move

  if ticks mod 52 = 0 [
    ask pros-on ina-patches [
      ask my-links [die]
      move-to-empty-one-of ina-patches
      create-friendships-with other n-of (count turtles-on ina-patches in-radius 5) turtles-on ina-patches in-radius 5
    ]
    ask pros-on abr-patches [
      ask my-links [die]
      move-to-empty-one-of abr-patches
      create-friendships-with other n-of (count turtles-on abr-patches in-radius 5) turtles-on abr-patches in-radius 5
    ]
  ]

end

to pro-create-link

  ask pros-on ina-patches [
    let num n-recruit self ina-patches 0.6
    create-friendships-with other n-of (num) students-on ina-patches in-radius 5
  ]
  ask pros-on abr-patches [
    let num n-recruit self abr-patches 0.8
    create-friendships-with other n-of (num) students-on abr-patches in-radius 5
  ]
end

to move-to-empty-one-of [ locations ]

  move-to one-of locations
  while [any? other turtles-here] [
    move-to one-of locations
  ]

end

to move [ dist ]

  right random 30
  left random 30
  let turn one-of [-10 10]
  while [ not land-ahead dist ] [
    set heading heading + turn
  ]
  forward dist

end

to scholarship

  ;; scholarship opportunity once a year
  if ticks mod 52 = 0 [
    ask students with [degree = "High School"] [
      if college = FALSE and capital < 113 and random-float 100 < scholarship-plus-ug [
        ;; chance to get scholarship 18%
        ;; scholarhip add 20 to basic capital
        set capital capital + 20 + (gdp-fund-tert-edu / gdp-fund)
      ]
    ]
   scholarship-pg
  ]

end

to scholarship-pg
  ask students with [college = FALSE and degree = "UG"] [
      if random-float 100 < scholarship-plus-pg [
        set capital capital + 60 + (gdp-fund-tert-edu / gdp-fund)
      ]
    ]
end

to emigrate

  ;; ask students with changed status to move abroad/domestic
  ask students [
    if status = "ABR" and pcolor = 19 [
      move-to-empty-one-of abr-patches
      ask students [
        create-friendships-with other n-of (count turtles-on abr-patches in-radius 10) turtles-on abr-patches in-radius 10
      ]
    ]
    if status = "INA" and pcolor = 99 [
    move-to-empty-one-of ina-patches
    ]
  ]

end

to study
  ;; study decision for undergraduate
  ask students [
    if capital >= 113 and color = green [
      set college TRUE
      set status "INA"
      set color black
      set study-time study-time-ug 0.5
      set degree "UG"

      if capital >= 141 [
        set college TRUE
        set status "ABR"
        set color yellow
        set study-time study-time-ug 0.5
        set degree "UG"
      ]
    ]
  ]
  earn-knowledge-ug
  earn-knowledge-pg
  graduate-ug
  study-pg

end

to earn-knowledge-ug ;; function to create knowledge in each agent

  if ticks mod 13 = 0 [ ;; assumed for each semester
    ask students with [degree ="UG" and college = TRUE] [
      set knowledge lput earn-knowledge 0.6 knowledge
    ]
  ]

end

to earn-knowledge-pg

  if ticks mod 13 = 0 [
    ask students with [degree ="PG" and college = TRUE] [
      set knowledge lput earn-knowledge 0.9 knowledge
    ]
  ]

end

to study-pg ;; study protocol for post graduate student

  ask students with [college = FALSE and degree = "UG"] [
    if capital >= 190 [
      set college TRUE
      set degree "PG"
      set study-time study-time-pg
      set color turquoise
      set status prob-pg-abr 0.9
    ]
  ]

end

to become-hs ;; protocol of changing post-graduate student become high-skilled worker

  ask students with [study-time <= 0 and degree = "PG" and college = TRUE] [
    set college FALSE
    set degree "HS"
    set color magenta
    set skill precision (sum knowledge / length knowledge) 2 ;; convert knowledge into skill
  ]

end

to get-married ;; protocol for agent if have spouse or not

  if ticks mod 26 = 0 [ ;; seek for spouse twice a year
    ask students with [degree = "HS" and married? = 0] [ ;; only for HS type and not yet married
      if random-float 100 < 60 [ ;; there are 60% probability for each agent to get married
        set married? 1
      ]
    ]
  ]

end

to graduate-ug

  ask students [
    if study-time = 0 and college = TRUE and degree = "UG" [
      set college FALSE
    ]
  ]

end

to aging

  if (ticks + 1) mod 52 = 0 [
    ask students [
      set age age + 1
    ]
    ask students with [college = true] [
      set study-time study-time - 1
    ]
  ]

end

to die-naturally ;; process to die for student who is not undergraduate and post graduate

  ask students with [age >= 21 and color = green] [ die ]
  ask students with [age >= 22 and college = FALSE and degree = "UG"] [ die ]

end

to link-die ;; secara random 20% dari link yang ada akan hilang

  if ticks mod 52 = 0 [
    ask friendships [
      if random-float 100 < 20 [
        die
      ]
    ]
  ]

end

to new-cohort

  if (ticks + 1) mod 52 = 0 [
    create-student
  ]

end

to hs-return ;; protocol for high skilled worker comeback to domestic

  if ticks mod 104 = 0 [
    ask students with [pcolor = 99 and degree = "HS"] [
      let decision-list (map * [0.125 0.125 0.125 0.125 0.2 0.3] perc-perspective self)
      ifelse random-float 100 < 30 [ ;; keputusan spouse
        let decision-abr (item 1 decision-list) + (item 3 decision-list) + (item 4 decision-list) + (item 5 decision-list)
        let decision-ina (item 0 decision-list) + (item 2 decision-list)
        if decision-ina > decision-abr [
          move-to-empty-one-of ina-patches
          set status "INA"
        ]
      ][
        let decision-abr (item 1 decision-list) + (item 3 decision-list) + (item 4 decision-list)
        let decision-ina (item 0 decision-list) + (item 2 decision-list) + (item 5 decision-list)
        if decision-ina > decision-abr [
          move-to-empty-one-of ina-patches
          set status "INA"
        ]
      ]
    ]
  ]

end


to set-sysdyn

  set agg-gdp contribution
  set total-ina-hs total-count-ina-hs

end

to-report land-ahead [ dist ]

  let target patch-ahead dist
  report target != nobody and shade-of? red [ pcolor ] of target

end

to-report Nina

  report count turtles-on ina-patches

end

to-report Nabr

  report count turtles-on abr-patches

end

to-report prob-pg-abr [ x ]

  report ifelse-value (random-float 1 < x) ["ABR"] ["INA"]

end

to-report study-time-ug [x] ;; probability of learning for undergraduate student

  report ifelse-value (random-float 1 < x) [4] [5]

end

to-report study-time-pg

  report item random 4 [2 3 4 5]

end

to-report earn-knowledge [ x ] ;; protocol to earning knowledge during study

  report ifelse-value (random-float 1 < x) [1] [0]

end

to year-tick

  if (ticks + 1) mod 52 = 0 [
    set year year + 1
  ]

end

to-report summary [ x ] ;; function to create summary statistics of a list value

  report (list (min x) (mean x) (median x) (standard-deviation x) (max x))
  ;; example:
  ;;         summary [attribute] of agentset

end

to-report perspective [x] ;; create list of friend, native, and recruiters of students

  let count-stu-ina count [link-neighbors with [breed = students and status = "INA"]] of x
  let count-stu-abr count [link-neighbors with [breed = students and status = "ABR"]] of x
  let count-na-ina  count [link-neighbors with [breed = native-inas]] of x
  let count-na-abr  count [link-neighbors with [breed = native-abrs]] of x
  let count-pro     count [link-neighbors with [breed = pros]] of x
  let count-married ([married?] of x) * 3
  report (list count-stu-ina count-stu-abr count-na-ina count-na-abr count-pro count-married)
  ;; example:
  ;;          perspective agent-num

end

to-report perc-perspective [x] ;; create list of friend, native, and recruiters of students

  let count-stu-ina count [link-neighbors with [breed = students and status = "INA"]] of x
  let count-stu-abr count [link-neighbors with [breed = students and status = "ABR"]] of x
  let count-na-ina  count [link-neighbors with [breed = native-inas]] of x
  let count-na-abr  count [link-neighbors with [breed = native-abrs]] of x
  let count-pro     count [link-neighbors with [breed = pros]] of x
  let count-married ([married?] of x) * 3
  let count-total sum perspective x
  let perc-stu-ina precision (count-stu-ina / count-total) 3
  let perc-stu-abr precision (count-stu-abr / count-total) 3
  let perc-na-ina precision (count-na-ina / count-total) 3
  let perc-na-abr precision (count-na-abr / count-total) 3
  let perc-pro precision (count-pro / count-total) 3
  let perc-married precision (count-married / count-total) 3
  report (list perc-stu-ina perc-stu-abr perc-na-ina perc-na-abr perc-pro perc-married)
  ;; example:
  ;;          perspective agent-num

end

to-report n-recruit [x y z] ;; create number of targeted list
  ;; x is agent
  ;; y is patches
  ;; z is percentage of student in the area that aimed to included
  report [round (count students-on y in-radius 5 * z) ]  of x
  ;; example:
  ;;         n-recruit agent-num patches prob

end

to-report perc-friends-nearby [ x ]

  let turtle-nearby [count turtles in-radius 5 - 1] of x
  let total-linked [count link-neighbors] of x
  if total-linked > 0 and turtle-nearby > 0 [
    report turtle-nearby / total-linked
  ]

end

to-report contribution

  report mean [capital] of students

end

to-report total-count-ina-hs

  report count students with [degree = "HS" and status = "INA"]

end
@#$#@#$#@
GRAPHICS-WINDOW
935
30
1444
540
-1
-1
4.9604
1
10
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
15
25
78
58
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
5
80
80
125
num-ug-abr
count students with [color = yellow]
2
1
11

MONITOR
85
80
160
125
num-ug-ina
count students with [color = black]
2
1
11

MONITOR
5
225
95
270
Total Students
count students
17
1
11

MONITOR
5
275
147
320
Graduated-ug-students
count students with [college = FALSE and degree = \"UG\"]
17
1
11

MONITOR
5
325
62
370
Year
year
17
1
11

BUTTON
170
25
295
58
setup go 8 years
setup repeat 52 * 8 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
5
125
80
170
num-pg-abr
count students with [degree = \"PG\" and status = \"ABR\"]
17
1
11

MONITOR
85
125
160
170
num-pg-ina
count students with [color = 75 and status = \"INA\"]
17
1
11

MONITOR
5
170
80
215
num-hs-abr
count students with [degree = \"HS\" and status = \"ABR\"]
17
1
11

PLOT
520
85
895
235
Number of Students
Ticks
Number of Student
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"ug-student" 1.0 0 -14070903 true "" "plot count students with [degree = \"UG\"]"
"post-graduate" 1.0 0 -5298144 true "" "plot count students with [degree = \"PG\"]"
"high-skilled" 1.0 0 -14439633 true "" "plot count students with [degree = \"HS\"]"

BUTTON
95
25
158
58
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
520
235
895
385
Degree Distribution of Students
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "let max-degree max [count link-neighbors] of students\nset-plot-x-range 0 (max-degree + 1)  ;; + 1 to make room for the wid\nhistogram [count link-neighbors] of students"

MONITOR
85
170
160
215
num-hs-ina
count students with [degree = \"HS\" and status = \"INA\"]
17
1
11

PLOT
520
385
895
540
Patents
Time
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Patents" 1.0 0 -2674135 true "" "plot patents"

PLOT
170
85
520
235
High Skilled Workers
Ticks
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"hs-ina" 1.0 0 -5298144 true "" "plot count students with [degree = \"HS\" and status = \"INA\"]"
"hs-abr" 1.0 0 -7500403 true "" "plot count students with [degree = \"HS\" and status = \"ABR\"]"
"pg-abr" 1.0 0 -14439633 true "" "plot count students with [status = \"ABR\" and degree =\"PG\"]"
"pg-ina" 1.0 0 -14070903 true "" "plot count students with [degree = \"PG\" and status = \"INA\"]"

SLIDER
320
10
502
43
scholarship-plus-ug
scholarship-plus-ug
0
100
41.0
1
1
%
HORIZONTAL

SLIDER
320
45
502
78
scholarship-plus-pg
scholarship-plus-pg
0
100
74.0
1
1
%
HORIZONTAL

SLIDER
525
45
705
78
tolerance-level-native-abr
tolerance-level-native-abr
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
525
10
705
43
tolerance-level-native-ina
tolerance-level-native-ina
0
1
0.51
0.01
1
NIL
HORIZONTAL

PLOT
170
235
520
385
Distribustion of Student's Capital
Capital
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"capital-all" 1.0 1 -14070903 true "" "let max-capital max [capital] of students\nlet min-capital min [capital] of students\nset-plot-x-range (min-capital - 10) (max-capital + 10)\nset-histogram-num-bars 30 ;; set number of bars in histogram plot\nhistogram [capital] of students"
"capital-pg" 1.0 1 -14439633 true "" "set-histogram-num-bars 30 ;; set number of bars in histogram plot\nhistogram [capital] of students with [degree = \"PG\"]"

PLOT
170
385
520
540
GDP Fund
Tick
NIL
0.0
10.0
0.0
0.03
true
false
"" ""
PENS
"gdp-fund-tert-edu" 1.0 0 -7500403 true "" "\nplot gdp-fund-tert-edu"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
2.0
    org.nlogo.sdm.gui.AggregateDrawing 20
        org.nlogo.sdm.gui.StockFigure "attributes" "attributes" 1 "FillColor" "Color" 225 225 182 251 107 60 40
            org.nlogo.sdm.gui.WrappedStock "gdp-fund" "0.04" 1
        org.nlogo.sdm.gui.ReservoirFigure "attributes" "attributes" 1 "FillColor" "Color" 192 192 192 79 110 30 30
        org.nlogo.sdm.gui.RateConnection 3 109 125 174 125 239 126 NULL NULL 0 0 0
            org.jhotdraw.figures.ChopEllipseConnector REF 3
            org.jhotdraw.standard.ChopBoxConnector REF 1
            org.nlogo.sdm.gui.WrappedRate "gdp-growth" "gdp-inflow"
                org.nlogo.sdm.gui.WrappedReservoir  REF 2 0
        org.nlogo.sdm.gui.ReservoirFigure "attributes" "attributes" 1 "FillColor" "Color" 192 192 192 499 106 30 30
        org.nlogo.sdm.gui.StockFigure "attributes" "attributes" 1 "FillColor" "Color" 225 225 182 296 314 60 40
            org.nlogo.sdm.gui.WrappedStock "Patents" "194" 0
        org.nlogo.sdm.gui.ReservoirFigure "attributes" "attributes" 1 "FillColor" "Color" 192 192 192 56 272 30 30
        org.nlogo.sdm.gui.RateConnection 3 86 290 185 308 284 326 NULL NULL 0 0 0
            org.jhotdraw.figures.ChopEllipseConnector REF 12
            org.jhotdraw.standard.ChopBoxConnector REF 10
            org.nlogo.sdm.gui.WrappedRate "(total-ina-hs * 2.2 ) / 52" "Incoming-patents"
                org.nlogo.sdm.gui.WrappedReservoir  REF 11 0
        org.nlogo.sdm.gui.ReservoirFigure "attributes" "attributes" 1 "FillColor" "Color" 192 192 192 392 270 30 30
        org.nlogo.sdm.gui.ConverterFigure "attributes" "attributes" 1 "FillColor" "Color" 130 188 183 139 187 50 50
            org.nlogo.sdm.gui.WrappedConverter "Patents * 0.017" "Tech-dev"
        org.nlogo.sdm.gui.ConverterFigure "attributes" "attributes" 1 "FillColor" "Color" 130 188 183 37 156 50 50
            org.nlogo.sdm.gui.WrappedConverter "Tech-dev * 0.016" "gdp-growth"
        org.nlogo.sdm.gui.BindingConnection 2 144 206 81 186 NULL NULL 0 0 0
            org.jhotdraw.contrib.ChopDiamondConnector REF 19
            org.jhotdraw.contrib.ChopDiamondConnector REF 21
        org.nlogo.sdm.gui.BindingConnection 2 78 172 174 125 NULL NULL 0 0 0
            org.jhotdraw.contrib.ChopDiamondConnector REF 21
            org.nlogo.sdm.gui.ChopRateConnector REF 4
        org.nlogo.sdm.gui.ConverterFigure "attributes" "attributes" 1 "FillColor" "Color" 130 188 183 348 211 50 50
            org.nlogo.sdm.gui.WrappedConverter "gdp-fund * 2.32339e-14 + 0.0156996" "gdp-fund-tert-edu"
        org.nlogo.sdm.gui.BindingConnection 2 284 302 178 222 NULL NULL 0 0 0
            org.jhotdraw.standard.ChopBoxConnector REF 10
            org.jhotdraw.contrib.ChopDiamondConnector REF 19
        org.nlogo.sdm.gui.BindingConnection 2 308 159 361 222 NULL NULL 0 0 0
            org.jhotdraw.standard.ChopBoxConnector REF 1
            org.jhotdraw.contrib.ChopDiamondConnector REF 29
        org.nlogo.sdm.gui.RateConnection 3 368 333 441 333 515 334 NULL NULL 0 0 0
            org.jhotdraw.standard.ChopBoxConnector REF 10
            org.jhotdraw.figures.ChopEllipseConnector
                org.nlogo.sdm.gui.ReservoirFigure "attributes" "attributes" 1 "FillColor" "Color" 192 192 192 514 319 30 30
            org.nlogo.sdm.gui.WrappedRate "Patents / patents-age" "patents-outflow" REF 11
                org.nlogo.sdm.gui.WrappedReservoir  0   REF 40
        org.nlogo.sdm.gui.ConverterFigure "attributes" "attributes" 1 "FillColor" "Color" 130 188 183 473 413 50 50
            org.nlogo.sdm.gui.WrappedConverter "1040" "patents-age"
        org.nlogo.sdm.gui.BindingConnection 2 489 421 441 333 NULL NULL 0 0 0
            org.jhotdraw.contrib.ChopDiamondConnector REF 43
            org.nlogo.sdm.gui.ChopRateConnector REF 37
        org.nlogo.sdm.gui.BindingConnection 2 368 333 441 333 NULL NULL 0 0 0
            org.jhotdraw.standard.ChopBoxConnector REF 10
            org.nlogo.sdm.gui.ChopRateConnector REF 37
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
