timeIntegrationMethod(imexorder1).
timeIntegrationMethod(imexorder2).
timeIntegrationMethod(imexorder3).
timeIntegrationMethod("dirkorder1").
timeIntegrationMethod("forwardeuler").
timeIntegrationMethod("backwardeuler").
timeIntegrationMethod("classicalrungekutta4").

physicsModel(monodomain).
physicsModel(bidomain).

physicsModelTI(monodomain, TI) :- timeIntegrationMethod(TI).
physicsModelTI(bidomain, imexorder1).
physicsModelTI(bidomain, imexorder2).
physicsModelTI(bidomain, imexorder3).

cellModelCheckpointing(1).
cellModelCheckpointing(0).

cellModelTI(0, TI) :- timeIntegrationMethod(TI).
cellModelTI(1, imexorder1).
cellModelTI(1, forwardeuler).
cellModelTI(1, backwardeuler).

timeIntegrationChoice(X, Model, Checkpointing) :- timeIntegrationMethod(X), physicsModelTI(Model, X), cellModelTI(Checkpointing, X).
