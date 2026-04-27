# Revisions on top of README.md (original)

Includes but is not limited to:
1. Multiplayer
2. Difficulty Implementation (Cooldown Period Time Set)
3. Bonus Conditions
4. "Continued Use" Implementations (soon)

---

**Formal Thesis Detail**

## Scope and Limitations

### Scope of the Study

Limited multiplayer demo functionality is included.

### Limitations of the Study

Multiplayer is limited only to local sessions, and no online functionality.

---

## Context Overview

The app uses the phone's front-facing camera to detect the player's body movements in real time via Google ML Kit Pose Detection. The game renders as a 2D overlay drawn directly on top of the live camera feed, creating an augmented reality effect. The player sees themselves on screen with game elements — composited as a layer over the camera image. The body is tracked, reps are counted, and those reps drive every game mechanic.

---

# Game Design

## Loop

### Workout Selection Screen 
The player is first shown a screen with two options:
- **Singleplayer**
- **Multiplayer**

If Singleplayer, display:
- **Squats**
- **Jumping Jacks**
- **Side Crunches**


If Otherwise multiplayer, display only **Jumping Jacks**. 

Player 1 is currently logged in. Then ask for an email address of Player 2, then email OTP PIN verification  to finally proceed. This is so session data can be reflected with player 2, and can prove account exists.

Then, options for adjusting cooldown time:
- A slider range between 05-25 seconds.
- Default 15 seconds

Then game loads. Game proper background for screen is asset: `asset/images/game/background.png`

### The Rounds Progression Loop

The game is a linear sequence of 10 rounds. Each round have you face off against a dragon gets closer and closer to your screen. The game wins when all 10 rounds are finished.

1. The loop begins with successful workout select parameters.
2. Upon selection, the cooldown period begins.
3. Then the round starts. The RED DUAL HEADED dragon appears with a health pool reflecing the number of reps, and at a large size.
4. The player must perform reps within at least a set amount of seconds (reps interval) depending on the workout:
    - Squats: 4 seconds
    - Jumping Jacks: 3 seconds
    - Side Crunches: 2 seconds
5. Each completed rep deals damage and reduces the dragon's health, and shrinks it gradually.
6. When the dragon's health reaches 0, the dragon returns to normal size, and then disappears.
7. A cooldown period then ensues.
8. After cooldown, the next round starts automatically (hands-free experience)
9. This loops throughout the game until the 10th round, but is periodically interrupted by the bonus round.
    
**Bonus rounds**

1. After completing rounds 5 and 10 a bonus round appears; Cooldown period ensues as usual.
2. A player has to complete 5 reps.
3. Instead of a RED dragon, a GOLDEN dragon takes its place.
4. A fixed timer of 15 seconds is counting down (from the rep interval timer)
5. In the bonus round, a player is to make however many reps possible. May be 0 or more.
6. Reps_made = -1 second to final clear time tally (if victorious session)
7. Upon defeat, GOLDEN dragon is slain (disappears from the screen)
8. If failed 1st bonus round (after round 5, before round 6) IS NOT A DEFEAT. Splash screen before cooldown period to proceed as normal.
9. If failed 2nd bonus round (after round 10, before game over) IS NOT A DEFEAT. Shows splash screen before results screen.
10. Cooldown period again upon finishing, awaiting the next round.
11. Bonus round pauses metric for clear time, will continue as normal for the next round.
12. Bonus rounds counts reps, and rep interval, and total round count.

**REPS TO WIN; NO BONUS ROUNDS counted**

| Round     | Reps to Win |
|-----------|-------------|
| 1         | 8           |
| 2         | 8           |
| 3         | 8           |
| 4         | 8           |
| 5         | 8           |
| 6         | 9           |
| 7         | 9           |
| 8         | 9           |
| 9         | 10          |
| 10        | 10          |
| **Total** | **87**      |  

### Bonus Splash Screen
- Before a cooldown period screen, and after bonus round.
- 3 seconds duration.
- Before bonus round: "BONUS -- Here's your chance to step up!"
- After bonus round, success: "GREAT JOB! -[XX] seconds to your clear time!"
- After bonus round, fail: "SHUCKS! Try again next time!"

## Multiplayer (Co-op)

The same generalgoes. But some differences:

1. The screen is split left and right. Left is player 1 (host) and right is player 2 (guest via email OTP during workout select).
2. Players are positioned accordingly.
3. The game is tracking the reps of both players 1 and 2.
4. Players should simultaneously rep together, and do it properly to register as a rep in the game.
5. If only 1 rep from the 2 players is detected, or both players did simultaneous reps but is done improperly, then that the rep is void.
6. Lives system is shared amongst both players.

**Multiplayer DB Storage**
- Results are the composite of Player 1 and 2, and session data is copied and saved with same data to different player IDs.
- Saves any 1 multiplayer session as two copies.
- 2 copies registered as both player 1 and 2.

## Dragons
- Displayed at the center middle of the screen.
- RED DRAGON is for a normal (not bonus round). A spreadsheet in `assets/images/game/flying_twin_headed_dragon-red-spritesheet-144x128.png`. 144 x 128px per frame.
- GOLD DRAGON is for bonus (not normal round). A spreadsheet in `flying_dragon-gold-spritesheet-144x128px.png`. 144 x 128px per frame.
- Looping flying animation (12 frames total, 3 per frame) 
- Must preserve original PNG aspect ratio; can be resized larger, but not stretched.
- Damage is visualized by the dragon flashing as a white silhouette very quickly (like in Zelda II)
- Damage also provides sonic feedback, `assets/audio/sfx/thud.mp3`

**Enemy Sizing**

- Any given Dragon starts at a certain large size (>100% of the original size) depending on the reps needed to be slain (8, 9, 10, or 5)
- The dragon, after every rep performed, gradually shrinks all the way back to 100% when the final rep is performed.
- The table

| Reps (8)  | Scale at rep start (%)   | Scale at rep done (%) |
|-----------|--------------------------|-----------------------|
| 1         | 164%                     | 156%                  |
| 2         | 156%                     | 148%                  |
| 3         | 148%                     | 140%                  |
| 4         | 140%                     | 132%                  |
| 5         | 132%                     | 124%                  |
| 6         | 124%                     | 116%                  |
| 7         | 116%                     | 108%                  |
| 8         | 108%                     | 100%                  |


| Reps (9)  | Scale at rep start (%)   | Scale at rep done (%) |
|-----------|--------------------------|-----------------------|
| 1         | 172%                     | 164%                  |
| 2         | 164%                     | 156%                  |
| 3         | 156%                     | 148%                  |
| 4         | 148%                     | 140%                  |
| 5         | 140%                     | 132%                  |
| 6         | 132%                     | 124%                  |
| 7         | 124%                     | 116%                  |
| 8         | 116%                     | 108%                  |
| 9         | 108%                     | 100%                  |

| Reps (10) | Scale at rep start (%)   | Scale at rep done (%) |
|-----------|--------------------------|-----------------------|
| 1         | 180%                     | 172%                  |
| 2         | 172%                     | 164%                  |
| 3         | 164%                     | 156%                  |
| 4         | 156%                     | 148%                  |
| 5         | 148%                     | 140%                  |
| 6         | 140%                     | 132%                  |
| 7         | 132%                     | 124%                  |
| 8         | 124%                     | 116%                  |
| 9         | 116%                     | 108%                  |
| 10        | 108%                     | 100%                  |

| Reps (5)  | Scale at rep start (%)   | Scale at rep done (%) |
|-----------|--------------------------|-----------------------|
| 1         | 140%                     | 132%                  |
| 2         | 132%                     | 124%                  |
| 3         | 124%                     | 116%                  |
| 4         | 116%                     | 108%                  |
| 5         | 108%                     | 100%                  |


## Lives System

### Dragon Life Steal
- When a player lost a life, a penalty is added so that the Dragon "steals" that life, and the health, ergo, reps required is increased.
- When a dragon steals that life, the dragon's sized is increase +8%, and the shrinking logic still continues to apply.
- If a player loses a life at 5 out of 8 (5/8) reps, then the player will perform an extra 1 rep.
- 5/8 is initially required, then player lost a life in the process, and will now display as 6/8.
- The logic extends to overflow, so hypothetically, we can have 9/8 or 10/8 required reps. (+1 and +2 respectively)
- When the last life is lost, the game ends as is established.
- Penalty is to replenish the enemy's health, not increase the reps required.
- The health bar may not overextend if overflown. Keep it at full until it falls below whole number (example, 7/8)
- Can count towards results to reps d one (may overflow 87 similar bonus round logic), and lifetime reps.

## Cooldown Period

- Duration: 5-30 seconds
- Clear time metric, Rep detection, and pace timer is paused throughout the duration
- Triggered before each round begins, and after each successful round.
- Round 10 will not play ending cooldown period, as game is over when beaten.
- Player can use this time to rest and prepare
- Cooldown sequence initiates automatically — no player input required.


### Victory
Displays session stats:
1. Fastest Clear time
2. Rounds Complete = rounds played/rounds total (2/10)
    - If bonus rounds exceed 10 total, then example, 12/10, for example.
3. Reps finished = reps performed/reps total
    - If bonus rounds exceed 87 total, then example, 95/87, for example.
4. Best Rep interval
5. Average Rep Interval

- Subtext: "You have finally slain the Red Dragon!"


### Defeat
Displays session stats 
1. ~~Fastest Clear time~~
2. Rounds Complete = rounds played/rounds total (2/10)
    - If bonus rounds exceed 10 total, then example, 12/10, for example.
3. Reps finished = reps performed/reps total
    - If bonus rounds exceed 87 total, then example, 95/87, for example.
4. ~~Best Rep interval~~
5. ~~Average Rep Interval~~
- Shows "Retry" and 'Quit" button, each with "Are you sure you want to [X]?" confirmation screen


## Aesthetics:

**New Revision will invert original positions of camera and main screen; Camera is now a small preview display on the top left of the scree. The Dragon + Background + White Flashing Overlay with (-1) hit FX will take center middle, and scaled up to accomodate**. Much of the rest is the same, but adjusted to all the changes made here so far.


# Knightly Avatar (Continued Use)

In the homepage, we will have the **Fitness Knight.** A digital avatar that works very similar to Facebook Messenger Notes or Instagram Notes.

- When user last logged in
- When user last opened the app
- When last session was done

These are the factors that will influence the Knight to display what notes. The notes will displayed will depend on disposition of player activity. Will intelligently determine based on player stats.

Which messages in particular is randomly selected for every homescreen load.

**Notifications**

Also sends out push notifications at least once (pending research on best time to send notifications)

*note: embedded within app. also may need to change schema columns in sessions to account for last_login_timestamp, last_session_timestamp, last_app_open_timestamp*

**Dialogue Sorted from good to bad disposition**

### Praises

**Criteria:** Consistent activity or daily streak of at least 1 session.

- "My armor is glowing from your gains! ✨🛡️"
- "Is it getting hot in here, or is that just your fire? 🥵"
- "Even the dragons are starting to look small to me. 🐉🤏"
- "A sharpened blade never rusts. Good work, squire. ⚔️"
- "Slow and steady wins the siege. Keep pushing. 🐢🏰"
- "Consistency: The secret weapon of every hero. 🛡️✅"

### Questioned

**Criteria:** Logged in/opened app multiple times, but NO session started.

- "You’ve opened the app a few times. My cardio is fine—how’s yours? 🙄"
- "Are we here to sweat, or are we here to window shop? 💅"
- "I’ve been standing by for three hours. My back hurts. 🧘‍♂️💢"
- "The gains don't make themselves while you scroll, friend. 🏋️‍♂️📱"
- "My grandmother swings a mace faster than you log a set. 👵💥"

### Concerned

**Criteria:** Hasn't logged in or opened app for 48-72 hours.

- "My adventures are lonely without your spirit. 🕯️"
- "I’m thinking of auditioning for a new user. One with sneakers. 👟"
- "Consistency is the truest armor. Don't let yours rust. 🛡️"
- "Your muscles are whispering my name. They miss me. 🥺"
- "Did a dragon get you? Blink twice if you’re trapped in a cave. 🐉"

### Inactive

**Criteria:** Inactivity for 1+ weeks.

- "I am eating my own leather boots for sustenance. 👢💀"
- "Dust. So much dust. I think a spider lives in my helmet now. 🕷️"
- "Is anyone there? Or am I just a nobody to you? 🌫️📱"
- "Is this... the end of our quest? I'll wait by the gate. 🏚️"
- "I’ve forgotten the sound of a heartbeat. 💓❓"

**Updating**

May periodically update/refresh status after a set amount of time.