timeIntegrationMethod("IMEXOrder1").
timeIntegrationMethod("IMEXOrder2").
timeIntegrationMethod("IMEXOrder3").
timeIntegrationMethod("DIRKOrder1").
timeIntegrationMethod("ForwardEuler").
timeIntegrationMethod("BackwardEuler").
timeIntegrationMethod("ClassicalRungeKutta4").

physicsModel("Monodomain").
physicsModel("Bidomain").

physicsModelTI("Monodomain", TI) :- timeIntegrationMethod(TI).
physicsModelTI("Bidomain", "IMEXOrder1").
physicsModelTI("Bidomain", "IMEXOrder2").
physicsModelTI("Bidomain", "IMEXOrder3").

cellModelCheckpointing(1).
cellModelCheckpointing(0).

cellModelTI(0, TI) :- timeIntegrationMethod(TI).
cellModelTI(1, "IMEXOrder1").
cellModelTI(1, "ForwardEuler").
cellModelTI(1, "BackwardEuler").

timeIntegrationChoice(X, Model, Checkpointing) :- 
	timeIntegrationMethod(X), 
	physicsModelTI(Model, X), 
	cellModelTI(Checkpointing, X).

% timeIntegrationChoice(X, "Bidomain", 0).
