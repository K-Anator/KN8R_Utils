Syncs leaderboard data between the RLS MPFRE and the server as well as notifying the server of some potentially useful FRE moments for later use in things such as chat messages and syncing UI elements between players.

Reimplementation of the old "/start" countdown timer using a timerevent that doesn't sleep the entire script and can have a random delay; configurable in KN8RUtils.lua. "!start [seconds]" will start a countdown starting at the specified number, if no arguement is given it uses the predefined value of 5; configurable in KN8RUtils.lua. 
Countdowns will also fail to start if one is already active.
