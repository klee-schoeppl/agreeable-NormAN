__includes [ "dag-related-subroutines.nls" "inquiry-and-reasoning-subroutines.nls" "communication-subroutines.nls" "network-creation-subroutines.nls" "miscellaneous-subroutines.nls"]

globals [
  hypothesis-value ;actual Boolean value of the instantiated hypothesis (world model)
  evidence-list ;List to store the actual values of the nodes designated as evidence (world model)
  optimal-posterior ;the optimal belief p(HYP| evidence list) about the hypothesis given access to all evidence nodes' actual values
  Bayes-net ;causal structure of the world model and of the agents' faithful subjective representations thereof
  hypothesis-node ;specification/ selection of the hypothesis nodes
  evidence-nodes  ;specification/ selection of the evidence nodes
  arguments ;list used to count the uses of each argument
  number-of-evidence ;number of pieces of evidence
  unconditional-hypothesis-probability
  evidence-probabilities-list ;marginal probabilities of each piece of evidence given the actual value of the hypothesis

  mean-squared-distance-from-optimal-posterior
  mean-belief
  mean-squared-distance-from-mean
  polarization-measure
  error-measure
]

turtles-own [
  agent-evidence-list ;stores which parcels/pieces of evidence this agent has seen
  agent-belief ;current degree of belief in the hypothesis
  current-evidence ;list index of the currently handled piece of evidence
  last-heard ;the number of the last-heard piece of evidence
  draws ;How many more draws before this agent reaches max-draws?
  initial-draws-list ;used to store which pieces of evidence this agent pre-drew last time
  heard ;list of indexes of the pieces of evidence this agent has already encountered
  update-total ;list of evidence-strengths for this agent
  initial-belief ;this agent's prior about HYP from before they drew or heard any evidence
  recency-list ;list of evidence this agent has encountered, from least to most recent (no duplicated)
  shared-counter ;how often has this agent shared any parcel?
  my-chattiness
  my-threshold
  polarities-list
  neighbors-polarity-list ;ordered list of the polarities of the most recent arguments received from each neighbor
  neighbors-list

  squared-distance-from-optimal-posterior
  squared-distance-from-mean
]

extensions [r Nw ]  ;table (as soon as we get to use 6.3, then the agents' memory about neighbors and arguments can go into just two tables)

;for typing agents
breed[As A]
breed[Bs B]

;*****************************************************************************************
;***********************THIS FILE CONTAINS ONLY THE MAIN MODEL FLOW **********************
;*****************************************************************************************


to setup
  my-clear-all
  reset-ticks

  carefully [
    loadDAG ;all routines to do with loading or modifying DAGs can be found at the bottom of this code file
  ][
    print "EXCEPTION: Please ensure you are providing a valid R-file in the chosen location."
    print error-message
    stop
  ]

  if reset-world-? [
    carefully [
      reset-evidence
    ][
      print "EXCEPTION: please ensure that your custom settings for the Bayesian network are sound."
      print error-message
      stop
    ]
    set reset-agents-initial-evidence-? true ;a new world necessitates new initial draws
  ]

  compute-optimal-posterior

  if reset-social-network-? [
    clear-turtles

    ;this optionally creates agents as belonging to two types


    carefully [
      if network = "wheel" [
         create-As number-of-agents
        create-network-wheel
      ]
    ][
      print "EXCEPTION: please ensure that your wheel network contains at least three agents."
      stop
    ]
    if network = "complete" [
       create-As number-of-agents
      create-network-complete]
    if network = "small-world" [
       carefully [
      create-network-small-world
    ][
      print "EXCEPTION: To create a small-world network, please make sure that [k] is less than half of [number-of-agents]."
      print error-message
      stop
      ]
    ]
    if network = "null" [ create-As number-of-agents
      create-network-null]

    set reset-agents-initial-evidence-? true ;a new network structure necessitates freshly initialized agents
  ]

  if use-types-? [
      let number-Bs precision (number-of-agents * percentage-type-B / 100) 0
      let number-As (number-of-agents - number-Bs)

      while [number-Bs > 0] [
      ask one-of As [set breed Bs
         set number-Bs number-Bs - 1
      ]





  ]]



  initialize-agents

  compute-polarization-measure

  setupPlots
end

to go

  if check-stoping-conditions [stop] ;Optionally, the simulation stops when all agents know all the evidence or when max-ticks is reached.

  if show-me-? [
    show (word "--------------------------------------------")
    show (word "NEW TICK: " ticks)
    show (word "--------------------------------------------")
    show (word "Step 1: Inquiry")
    show (word "--------------------------------------------")
  ]

  ask turtles [
    if shouldInquire? [
      collectEvidence "random"
    ]
  ]

if show-me-? [
    show (word "--------------------------------------------")
    show (word "Step 2: COMMUNICATION")
    show (word "--------------------------------------------")
  ]

  ask turtles [
    if shouldShare? [
      ifelse breed = As [
        if share = "impact" [impactShare]
        if share = "random" [randomShare]
        if share = "recent" [simpleRecentShare]
        if share = "sample" [sample-share]
      ][
        if share-type-B = "impact" [impactShare]
        if share-type-B = "random" [randomShare]
        if share-type-B = "recent" [simpleRecentShare]
        if share-type-B = "sample" [sample-share]
      ]
    ]
  ]

  compute-polarization-measure
  plotArguments
  tick


 end
@#$#@#$#@
GRAPHICS-WINDOW
0
10
363
374
-1
-1
10.76
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
885
84
1040
117
number-of-agents
number-of-agents
1
100
20.0
1
1
NIL
HORIZONTAL

BUTTON
376
171
453
205
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

SWITCH
607
126
760
159
show-me-?
show-me-?
1
1
-1000

BUTTON
531
172
594
205
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

BUTTON
462
172
525
205
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
885
37
1040
82
network
network
"wheel" "complete" "small-world" "null"
2

PLOT
848
377
1353
630
Histogram of beliefs
Degree of belief
Number of people
0.0
1.01
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -16777216 true "" "histogram [agent-belief] of turtles"

SLIDER
1056
175
1229
208
initial-draws
initial-draws
0
10
1.0
1
1
NIL
HORIZONTAL

CHOOSER
1056
211
1210
256
share
share
"random" "impact" "recent" "sample"
1

MONITOR
835
320
945
365
optimal-posterior
optimal-posterior
4
1
11

MONITOR
376
272
831
317
evidence-list
evidence-list
17
1
11

SLIDER
1258
310
1398
343
repeater
repeater
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
1056
32
1228
65
chattiness
chattiness
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1056
69
1229
102
conviction-threshold
conviction-threshold
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
1056
105
1228
138
curiosity
curiosity
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1056
140
1228
173
maximum-draws
maximum-draws
0
10
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
1056
10
1206
28
Agent variables
11
0.0
1

SLIDER
885
124
1040
157
k
k
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
885
159
1041
192
rewiring-probability
rewiring-probability
0
1
0.2
0.01
1
NIL
HORIZONTAL

CHOOSER
1259
265
1397
310
approximation
approximation
"gRain" "seed" "repeater"
0

PLOT
9
377
845
630
The rise and fall of arguments
ticks
# of usages
0.0
10.0
0.0
1.0
true
true
"" ""
PENS

SLIDER
1244
39
1464
72
hypothesis-probability
hypothesis-probability
0
1
1.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
1245
10
1395
28
The World
11
0.0
1

MONITOR
835
273
945
318
hypothesis-value
hypothesis-value
17
1
11

CHOOSER
1246
75
1413
120
causal-structure
causal-structure
"big net" "small net" "asia" "alarm" "SallyClark" "Vole" "WetGrass" "custom"
5

INPUTBOX
249
770
785
830
path-to-custom-DAG
/this/is/the/file/path/to/where/you/stored/your/customDAG.R
1
0
String

TEXTBOX
255
668
860
773
If you want to load a [causal-structure] via an external R-file, please manually enter the [path-to-custom-DAG]. In addition, please decide upon a [hypothesis-node-custom-DAG], and upon [evidence-nodes-custom-DAG].\n\nIf you are using a pre-set [causal-structure], you may either use the preset [evidence-nodes] and [hypothesis-node], or enter your own selection and toggle [custom-evidence-and-hypothesis-?] on.
11
0.0
1

INPUTBOX
1407
275
1478
335
seed
1.0
1
0
Number

TEXTBOX
375
10
763
40
When first initializing the model or when switching [causal-structure], toggle on [reset-world-?] before using [setup] .
11
0.0
1

INPUTBOX
9
658
248
892
evidence-nodes-custom-DAG
E1\nE2\nE3\nE4
1
1
String

INPUTBOX
249
831
455
891
hypothesis-node-custom-DAG
H0
1
0
String

SWITCH
456
831
766
864
custom-evidence-and-hypothesis-?
custom-evidence-and-hypothesis-?
1
1
-1000

SWITCH
370
56
523
89
reset-world-?
reset-world-?
0
1
-1000

MONITOR
376
225
831
270
evidence-nodes
evidence-nodes
17
1
11

MONITOR
835
226
945
271
NIL
hypothesis-node
17
1
11

SWITCH
370
91
555
124
reset-social-network-?
reset-social-network-?
0
1
-1000

SWITCH
370
126
605
159
reset-agents-initial-evidence-?
reset-agents-initial-evidence-?
0
1
-1000

SWITCH
557
91
760
124
stop-at-full-information-?
stop-at-full-information-?
1
1
-1000

TEXTBOX
887
15
1037
33
Social network
11
0.0
1

MONITOR
376
320
831
365
evidence-probabilities-list
evidence-probabilities-list
3
1
11

TEXTBOX
1314
246
1450
267
BnLearn variables\n
11
0.0
1

CHOOSER
646
162
759
207
plotting-type
plotting-type
"uttered" "sent to" "received as novel"
0

INPUTBOX
785
100
860
160
max-ticks
25.0
1
0
Number

SWITCH
526
56
760
89
stop-at-max-ticks-?
stop-at-max-ticks-?
0
1
-1000

SLIDER
1654
41
1858
74
initial-draws-chance
initial-draws-chance
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
1653
78
1825
111
max-shares
max-shares
0
100
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
1680
20
1830
38
more drawing options
12
0.0
1

SWITCH
1653
119
1835
152
use-max-shares-?
use-max-shares-?
1
1
-1000

SWITCH
1664
381
1803
414
use-types-?
use-types-?
0
1
-1000

SLIDER
1664
417
1854
450
percentage-type-B
percentage-type-B
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
1664
456
1836
489
chattiness-B
chattiness-B
0
1
1.0
0.01
1
NIL
HORIZONTAL

TEXTBOX
1662
196
1810
226
sampling rule options
12
0.0
1

SWITCH
1654
217
1840
250
pairwise-sharing-?
pairwise-sharing-?
0
1
-1000

SWITCH
1654
254
1840
287
stochastic-sampling-?
stochastic-sampling-?
1
1
-1000

TEXTBOX
1681
358
1806
376
types\n
12
0.0
1

SWITCH
1654
291
1906
324
tendency-towards-impact-?
tendency-towards-impact-?
0
1
-1000

CHOOSER
1665
493
1803
538
share-type-B
share-type-B
"random" "impact" "recent" "sample"
3

SLIDER
1665
540
1922
573
conviction-threshold-type-B
conviction-threshold-type-B
0
1
0.0
0.01
1
NIL
HORIZONTAL

MONITOR
1247
126
1495
171
NIL
unconditional-hypothesis-probability
3
1
11

SWITCH
1246
177
1560
210
use-unconditional-hypothesis-probability-?
use-unconditional-hypothesis-probability-?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

NormAN 1.0 is the first implementation of the NormAN framework. NormAN – short for Normative Argument Exchange across Networks – is a framework for agent-based modelling of argument exchange in social networks, first presented in ’A Bayesian Agent-Based Framework for Argument Exchange Across Networks’. A detailed explanation of all model parameters can be found there. (Full reference: Assaad, L., Fuchs, R., Jalalimanesh, A., Phillips, K., Schöppl, L. & Hahn, U. (2023). ’A Bayesian Agent-Based Framework for Argument Exchange Across Networks’.) 

**This is the model’s process in a nutshell:** To argue about a central claim, agents exchange arguments for believing that claim to be true or false. What evidence exists is determined by the world and its causal structure: for example, if a patient has lung cancer, it is more likely than not that they have shortness of breath. NormAN uses this to generate ‘worlds’ in which argument exchange takes place. Agents can collect evidence from the world and they can communicate with one another by sharing that evidence as arguments across the social network.

To capture this process, NormAN has three components: a ground truth ‘world’ model, individual agents, and the social network across which these agents communicate. 

* The ground truth world determines the true state of the claim at issue, along with the evidence for it that could be discovered in principle. 

* Agents receive evidence about that world (through inquiry) and may communicate that evidence to others as arguments and receive it in turn. Agents aggregate all evidence/arguments that they have encountered to form a degree of belief in the target
claim. To this end, they use Bayes’ rule. 

* Communication, finally, takes place across a social network.

NormAN 1.0 offers the user the possibility to change each of these components and thus explore a variety of different argumentation scenarios. The model captures different communication styles, different world models and social networks. Issues that can be addressed with NormAN include (but are not limited to): polarization and the emergence of consensus, the diffusion of arguments across social networks, the truth-tracking potential of deliberative bodies, and many more.

## HOW TO USE IT?

Follow these steps to quickly initialize the model: 

1. When first opening the model, make sure ‘reset-world-?’
and ‘reset-social-network-?’ are on. 
2. The World: choose a ‘causal-structure’ (chooser). 
3. The social network:
choose a ‘social-network’ (chooser) and a ‘number-of-agents’ (slider). 
4. Click setup: the social network will appear in the interface, the right bottom monitor will show a histogram of agent-beliefs and the middle output will
show which pieces of evidence are true. 
5. Press ‘go’ to start the simulation 

By clicking ‘setup’, users can wholly re-initialize the model, or keep some model facets fixed. Switching ‘reset-world-?’ on resets the truth values of the evidence nodes when ‘ setup’ is pressed. ‘reset-social-network-?’ resets all agents and the social network that connects them. ‘reset-agents-initial-evidence-?’ resets the set of evidence that each agent starts with upon initialization (only relevant if initial-draws>0). Note that because these facets are interconnected, ‘reset-world-?’ triggers‘reset-agents-initial-evidence?’ and so does ‘reset-social-network-?’.

If you would like to monitor what each agent does each round, toggle on ‘show-me-?’: each agent will output their exact step-by-step behaviour as lines in the Command Center. 

The ‘plotting-type’ chooser gives three options for visualizing the frequency of shared arguments (in the plot entitled ‘The rise and fall of arguments’): ‘uttered’ tracks how many times a piece of evidence has been shared each round. ‘sent-to’ tracks how many agents an argument was sent to. ‘received-as-novel’ tracks how many times
an argument was received as a novelty by an agent.

## THINGS TO NOTICE

There are many things to notice. For example, notice how the dynamics of the evidence exchange (illustrated in the window ‘The rise and fall of arguments’) change when you alter the agents’ sharing rule (e.g., from impact to random). Also, observe how using less dense social networks (e.g., from complete to wheel) slows down the evolution of the agents’ beliefs.

## THINGS TO TRY

A phenomenon of interest in NormAN is whether agents reach a consensus (see window ‘Histogram of beliefs’). This will depend on all the factors mentioned above, and changing any model component can help or hinder consensus building. It is, therefore, a worthwhile endeavour to determine which parameter combinations lead to consensus.

## EXTENDING THE MODEL

As explained in ‘A Bayesian Agent-Based Framework for Argument Exchange Across Networks’ (Assaad et al., 2023), NormAN can (and should be) extended in many ways. One thing you can do easily is add new Bayesian networks to NormAN. Additional Bayesian networks must be written in bnlearn code (as in our code) and can be transferred to the NetLogo model via a path to an external R (bnlearn) file by entering the file path in ‘path-to-custom-dag’. Alternatively, you can "copy and paste" the bnlearn file into our NetLogo code (in the designated area at the bottom). Here is the step-by-step protocol to do this: 

1. Create bnlearn code of a Bayesian network.
2. In the UI: Select ‘causal-net = custom’. Specify which nodes ought to count as evidence (‘evidence-Nodes- Custom-DAG’) and hypothesis. Make sure you write each node’s name into one separate line (as in the preset). 
3. Go into the code. Copy and paste the code into the indicated slot (under "LoadCustomNet“). Make sure each line is embedded like so: r:eval "library(bnlearn)“. Make sure the syntax is correct (e.g., R is sensitive to differences such in punctuation, and NetLogo prefers ‘<-’ to ‘=’). Lastly, note that the evidence and hypothesis nodes must take the values ‘yes’ and ‘no’. In the preset ‘Sally Clark’ network, for instance, we changed the values ‘SIDS’ to ‘no’ and ‘murder’ to ‘yes’.

For those who are familiar with NetLogo, it should also be straightforwardly possible to add new communication rules and new social networks.

## CREDITS AND REFERENCES

**SOFTWARE**

* **NetLogo R extension**
Thiele, JC; Grimm, V (2010). “NetLogo meets R: Linking agent-based models with a toolbox for their analysis.” Environmental Modelling and Software, Volume 25, Issue 8: 972 - 974 [DOI: 10.1016/j.envsoft.2010.02.008]

* **bnlearn package**
Scutari M (2010). “Learning Bayesian Networks with the bnlearn R Package.” Journal of Statistical Software, 35(3), 1–22. doi:10.18637/jss.v035.i03.

**SOCIAL NETWORKS**

* **NetLogo Nw Extension and small-world networks**
<https://ccl.northwestern.edu/netlogo/docs/nw.htmlnw:generate-watts-strogatz> 
Wilensky, U. (2015). NetLogo Small Worlds model.http://ccl.northwestern.edu/netlogo/models/SmallWorlds. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* **Wheel and Cycle**
Frey, Daniel, and Dunja Šešelja. “Robustness and idealizations in agent-based models of scientific interaction.” The British Journal for the Philosophy of Science (2020).
https://github.com/daimpi/SocNetABM/tree/RobIdeal.

**BAYESIAN NETWORKS**

* **Alarm**
Accessed via bnlearn ‘Bayesian Network Repository’- www.bnlearn.com/bnrepository/ (updated Nov 2022). Originally found in: I. A. Beinlich, H. J. Suermondt, R. M. Chavez, and G. F. Cooper. The ALARM Monitoring System: A Case Study with Two Probabilistic Inference Techniques for Belief Networks. In Proceedings of the 2nd European Conference on Artificial Intelligence in Medicine, pages 247-256. Springer-Verlag, 1989.

* **Asia**
Accessed via bnlearn ‘Bayesian Network Repository’- www.bnlearn.com/bnrepository/ (updated Nov 2022). Originally found in: S. Lauritzen, and D. Spiegelhalter. Local Computation with Probabilities on Graphical Structures and their Application to Expert Systems (with discussion). Journal of the Royal Statistical Society: Series B (Statistical Methodology), 50(2):157-224, 1988.

* **Wet Grass**
Accessed via ‘agena.ai.modeller’ software (version 9336, www.agena.ai) model library. Originally found in: F. V. Jensen. Introduction to Bayesian Networks. Springer-Verlag, 1996.

* **Sally Clark**
Accessed via ‘agena.ai.modeller’ software (version 9336, www.agena.ai) model library. The AgenaRisk software contains a model library with executable versions of all models found in this book: F. Norman, and M. Neil. Risk assessment and decision analysis with Bayesian networks. Crc Press, 2018. Discussed in: N. Fenton. Assessing evidence and testing appropriate hypotheses. Sci Justice, 54(6):502–504, 2014. https://doi.org/10.1016/j.scijus.2014.10.007.

* **Vole**
Accessed via ‘agena.ai.modeller’ software (version 9336, www.agena.ai) model library. The AgenaRisk software contains a model library with executable versions of all models found in this book: F. Norman, and M. Neil. Risk assessment and decision analysis with Bayesian networks. Crc Press, 2018. Originally found in: Lagnado, D. A. “Thinking about evidence.” In Proceedings of the British Academy, vol. 171, pp. 183-223. Oxford, UK: Oxford University Press, 2011. Revised by: F. Norman, M. Neil, and D. A. Lagnado. A general structure for legal arguments about evidence using Bayesian networks. Cognitive science, 37(1): 61-102, 2013.

## HOW TO CITE
Assaad, L., Fuchs, R., Jalalimanesh, A., Phillips, K., Schöppl, L. & Hahn, U. (2023). “A Bayesian Agent-Based Framework for Argument Exchange Across Networks”.
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
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="collective-random-vole" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>polarization-measure</metric>
    <metric>error-measure</metric>
    <enumeratedValueSet variable="reset-agents-initial-evidence-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="path-to-custom-DAG">
      <value value="&quot;/this/is/the/file/path/to/where/you/stored/your/customDAG.R&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-me-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evidence-nodes-custom-DAG">
      <value value="&quot;E1\nE2\nE3\nE4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-max-shares-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-social-network-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="approximation">
      <value value="&quot;gRain&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-full-information-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tendency-towards-impact-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="causal-structure">
      <value value="&quot;Vole&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness-B">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws-chance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-shares">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plotting-type">
      <value value="&quot;uttered&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-type-B">
      <value value="&quot;sample&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-types-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-type-B">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-node-custom-DAG">
      <value value="&quot;H0&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pairwise-sharing-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-max-ticks-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="curiosity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-unconditional-hypothesis-probability-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-evidence-and-hypothesis-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeater">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold-type-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stochastic-sampling-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-world-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="collective-impact-vole" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>polarization-measure</metric>
    <metric>error-measure</metric>
    <enumeratedValueSet variable="reset-agents-initial-evidence-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="path-to-custom-DAG">
      <value value="&quot;/this/is/the/file/path/to/where/you/stored/your/customDAG.R&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-me-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evidence-nodes-custom-DAG">
      <value value="&quot;E1\nE2\nE3\nE4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-max-shares-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-social-network-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="approximation">
      <value value="&quot;gRain&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-full-information-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tendency-towards-impact-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="causal-structure">
      <value value="&quot;Vole&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness-B">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws-chance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-shares">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plotting-type">
      <value value="&quot;uttered&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-type-B">
      <value value="&quot;sample&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-types-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-type-B">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-node-custom-DAG">
      <value value="&quot;H0&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pairwise-sharing-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-max-ticks-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="curiosity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-unconditional-hypothesis-probability-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-evidence-and-hypothesis-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeater">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold-type-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stochastic-sampling-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-world-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share">
      <value value="&quot;impact&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="pairwise-random-vole" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>polarization-measure</metric>
    <metric>error-measure</metric>
    <enumeratedValueSet variable="reset-agents-initial-evidence-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="path-to-custom-DAG">
      <value value="&quot;/this/is/the/file/path/to/where/you/stored/your/customDAG.R&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-me-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evidence-nodes-custom-DAG">
      <value value="&quot;E1\nE2\nE3\nE4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-max-shares-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-social-network-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="approximation">
      <value value="&quot;gRain&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-full-information-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tendency-towards-impact-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="causal-structure">
      <value value="&quot;Vole&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness-B">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws-chance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-shares">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plotting-type">
      <value value="&quot;uttered&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-type-B">
      <value value="&quot;sample&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-types-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-type-B">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-node-custom-DAG">
      <value value="&quot;H0&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pairwise-sharing-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-max-ticks-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="curiosity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-unconditional-hypothesis-probability-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-evidence-and-hypothesis-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeater">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold-type-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stochastic-sampling-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-world-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="pairwise-impact-vole" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>polarization-measure</metric>
    <metric>error-measure</metric>
    <enumeratedValueSet variable="reset-agents-initial-evidence-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="path-to-custom-DAG">
      <value value="&quot;/this/is/the/file/path/to/where/you/stored/your/customDAG.R&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-me-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="evidence-nodes-custom-DAG">
      <value value="&quot;E1\nE2\nE3\nE4&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-max-shares-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-social-network-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="approximation">
      <value value="&quot;gRain&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-full-information-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tendency-towards-impact-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-agents">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="causal-structure">
      <value value="&quot;Vole&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness-B">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-draws-chance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-shares">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="plotting-type">
      <value value="&quot;uttered&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chattiness">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share-type-B">
      <value value="&quot;sample&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-types-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-type-B">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-node-custom-DAG">
      <value value="&quot;H0&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pairwise-sharing-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stop-at-max-ticks-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hypothesis-probability">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="curiosity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-unconditional-hypothesis-probability-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="custom-evidence-and-hypothesis-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="repeater">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conviction-threshold-type-B">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="k">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maximum-draws">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stochastic-sampling-?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reset-world-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share">
      <value value="&quot;impact&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
0
@#$#@#$#@
