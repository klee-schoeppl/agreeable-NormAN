### PROJECT DESCRIPTION

This repository contains an extension of the *NormAN* base model. NormAN – short for Normative Argument Exchange across Networks – is a framework for agent-based modelling of argument exchange in social networks, first presented in Assaad, L., Fuchs, R., Jalalimanesh, A., Phillips, K., Schöppl, K. & Hahn, U. (2023). *“A Bayesian Agent-Based Framework for Argument Exchange Across Networks“*. A detailed explanation of the base model and its parameters can be found there.

To study the impacts of agreeableness, we implemented three changes to the base model.
* An option for agents to communicate pair-wise, to satisfy their preference for agreeableness in local, one-on-one communication. In the base model, agents always communicate to all of their link-neighbors at once. Our extension allows us to contrast scenarios where agents communicate with each of their neighbours individually with a scenario in which they indiscriminately broadcast to their entire network.
* We added heterogeneity to the base model, in the form of implicitly typed agents. To allow the study of parts of the agent population having a preference for agreeableness in their communication, we extended the model to allow mixing of two agent types making use of any two communication rules.
* We implemented ‘sample’-sharing, an agreeable communication rule: agents using sample-sharing keep track of the polarities of each of their neighbours last-asserted argument. When communicating to these neighbours, agreeable agents will then assert arguments of matching polarity back to them, in an attempt to minimize tension. This process is straightforward in pairwise communication, and handled via majority rule when broadcasting to multiple neighbours at once.

A detailed description and application of this extension can be found in Schöppl, K. and Hahn, U. (forthcoming) *“Exploring Effects of Self-Censoring through Agent-Based Simulation“*.
