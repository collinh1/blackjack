#!/usr/bin/env bash

# Function: Command Line Blackjack
# Author: Collin H

# Resize the terminal window (to make sure the `splash screen' fits)
resize -s 30 100
stty rows 30
stty cols 100

# Clear the screen
clear

# Print the `splash screen'
cat <<'endOfSplashScreen'
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 X |/                           X
 x |\     Command Line          X
 X .        Blackjack           X
 X(_) +--------------------+    X
 X ^  | ,'`.   \,.,.,./  /\|    X
 X    |(_,._)  || o|o||  |||    X
 X    |  /\   _ll  ~ ll_ |||    X
 X    |    ,-'  ',,,,'/ '|||    X
 X    | .-':\.\ .. /./:^ |||    X
 X    |'   ^:\.\VV/./:^  |||    X
 X    |,.\  ^:\_\/_/:^  .|||    X
 X    |E3 ) ^:)_{}_(:^ ( E3|    X
 X    |||'  ^:/ /\ \:^  \`'|    X
 X    |||  ^:/'/^^\'\:^   ,|    X
 X    ||| ^:/'/ '' \'\:_,- |    X
 X    |||,_/,"""", _,-'    |    X
 X    |||  ll ~  ll   _\/_ |    X
 X    |||  ||o|o ||  (    )|    X
 X    |\/  /'`'`'`\   `.,' |  v X
 X    +--------------------+ (`)X
 X     Created by:            v X
 X        Collin H           \| X
 X                           /| X
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
endOfSplashScreen
sleep 0.5

# Define the variables
money=1000
bet=0 # Player initial bet
sbet=0 # Player split bet
pHand=() # Array containing the player's drawn cards
sHand=() # Array for 2nd hand, if the player splits
dHand=() # Array containing the dealer's drawn cards
pTotal=0 # Total value of the cards in player's hand
sTotal=0 # Total value of player's split hand
dTotal=0 # Total value of the cards in dealer's hand
cardFace=("A" "2" "3" "4" "5" "6" "7" "8" "9" "10" "J" "Q" "K")
split=1 # Boolean to control player's ability to split
playGo=0 # Boolean for player's decision loop
action="" # Player's choice to hit/stand/etc.
quit=1 # Boolean used to end the game's while loop
endRound=1 # Boolean used to end each round
games=0
wins=0
losses=0
pushes=0
timesSplit=0

# Function to simplify the (random) card drawing
function drawACard() {
        local newCard=$RANDOM # Generate a random number
	let "newCard %= 13" # Scale the number within the bounds 1-13
	echo $newCard
}

# Function to calculate value of the cards in hand
function handTotal() {
	local runTotal=0
	declare -a argHand=("${!1}")
	for i in "${argHand[@]}"; do # Calculate the value the hand with Aces=11
		if [[ $i -eq 0 ]]; then
			runTotal=$((runTotal + 11))
		elif [[ $i -gt 9 ]]; then
			runTotal=$((runTotal + 10))
		else
			runTotal=$((runTotal + i))
			runTotal=$((runTotal + 1))
		fi
	done
	if [[ $runTotal -gt 21 ]]; then # If hand is bust, recalculate with Aces=1
		runTotal=0
		for i in "${argHand[@]}"; do
                	if [[ $i -gt 9 ]]; then
                        	runTotal=$((runTotal + 10))
                	else
                        	runTotal=$((runTotal + i))
                        	runTotal=$((runTotal + 1))
                	fi
		done
	fi
	echo $runTotal
}

# Function to update the mid-game display
function updateDisplay() {
	clear # Clear the screen, then print the cards/options
        echo -ne "Game: $games   Your Bet: \$$bet"
        if [[ "$split" -eq 0 ]] && [[ "$sbet" -gt 0 ]]; then
		echo -ne " Split Bet:\$$sbet"
	fi
	echo -e "\nDealer:"
	if [[ "$endRound" -eq 0 ]]; then
        	echo -n "|X| "
        else
		echo -n "|${cardFace["${dHand[0]}"]}| "
	fi
	for card in "${dHand[@]:1}"; do
                echo -n "|${cardFace["$card"]}| "
        done
        echo -e "\n$name: "
        for card in "${pHand[@]}"; do
                echo -n "|${cardFace["$card"]}| "
        done
	if [[ "$split" -eq 0 ]]; then
		echo -e "\n"
		for card in "${sHand[@]}"; do
			echo -n "|${cardFace["$card"]}| "
		done
	fi
        echo -e "\n "
}

# Get the player's name to personalize the experience
echo -n "Enter your name: "
read name

# This is where the game starts
while [[ "$quit" -eq 1 ]]; do # Continue play until player chooses to quit

	# Player Statistics Screen
	clear
	echo "$name""'s" "Statistics"
	echo -e "\nGames Played: $games\n\nWins: $wins\nLosses: $losses\nPushes: $pushes\nSplit hands: $timesSplit\n\nMoney: \$$money"
	sleep 1

	# Take the player bet
	bet=0
	sbet=0
	# Player cannot bet less than 50 or more than $money
	while [[ "$bet" -lt 50 ]]; do
		echo -e "\nMin bet: \$50"
		echo -n "Enter your bet: "
		read bet
		if [[ "$bet" -gt "$money" ]]; then
			bet=$money
			echo -e "\nYou bet the maximum: \$$money"
		fi
	done
	sleep 1

	# Draw the initial (first 2) cards
	games=$((games + 1)) # Add 1 to the number of games played
	pTotal=0
	sTotal=0
	dTotal=0
	dHand[0]=$(drawACard)
	dHand[1]=$(drawACard)
	pHand[0]=$(drawACard)
	pHand[1]=$(drawACard)


	# Cycle to allow player to hit/stand/double down/split
	endRound=0
	split=1
	while [[ $endRound -eq 0 ]]; do
		echo -e "$(updateDisplay)" # Display dealer/player hands
		dTotal=$(handTotal dHand[@]) # Calculate dealers hand value
		pTotal=$(handTotal pHand[@]) # Repeat for the player
		if [[ "$split" -eq 0 ]]; then
			sTotal=$(handTotal sHand[@])
		fi
		playGo=0 # Set playGo to 0, otherwise it will skip the `action` loop
		if [[ "$endRound" -eq 0 ]] && [[ "$pTotal" -lt 21 ]]; then
		while [[ "$playGo" -eq 0 ]]; do # Player chooses action
			if [[ "${pHand[0]}" -eq "${pHand[1]}" ]] && [[ "$split" -eq 1 ]]; then
				read -p "Hit,Stand,Double Down, or Split (h/s/d/x): " action
			else
				read -p "Hit,Stand, or Double Down(h/s/d): " action
			fi
			case "$action" in

				"h"|"H")
				  playGo=1
				  pHand=("${pHand[@]}" "$(drawACard)")
				  split=0
	                          echo "Hit"
				  ;;

				"s"|"S")
				  playGo=1
				  endRound=1
				  echo "Stand"
				  ;;

				"d"|"D")
				  if [[ $(($((bet * 2)) + sbet)) -le $money ]]; then
				    playGo=1
				    bet=$((bet * 2))
	                            pHand=("${pHand[@]}" "$(drawACard)")
				    pTotal=$(handTotal pHand[@])
         	             	    endRound=1
                        	    echo "Double Down"
				  else
				    echo "Insufficient funds"
				  fi
				  ;;

				"x"|"X")
				  if [[ "${pHand[0]}" -eq "${pHand[1]}" ]] && [[ $((bet * 2)) -le $money ]]; then
				    echo "Split"
				    pHand=("${pHand[0]}")
				    sHand=("${pHand[0]}")
				    playGo=1
				    split=0
				    sbet=$bet
				  elif [[ $((bet * 2)) -gt $money ]]; then
				    echo "Insufficient funds"
				  else
				    echo "Incorrect Choice"
				  fi
				  ;;

				*)
				  echo "Incorrect Choice"
				  ;;
			esac
			sleep 1
		done
		elif [[ "$pTotal" -ge 21 ]]; then # If player busted, end the round
			endRound=1
		fi
	done
	if [[ "$split" -eq 0 ]] && [[ "$sbet" -ge 50 ]]; then
	endRound=0
	while [[ "$endRound" -eq 0 ]] && [[ "$sTotal" -lt 21 ]]; do
		echo -e "$(updateDisplay)" # Display dealer/player hands
		sTotal=$(handTotal sHand[@]) # Calculate split hand value
		if [[ "$sTotal" -ge 21 ]]; then
			endRound=1
		fi
		playGo=0 # Set playGo to 0, otherwise it will skip the `action` loop
		if [[ "$endRound" -eq 0 ]]; then
		while [[ "$playGo" -eq 0 ]]; do # Player chooses action
			read -p "Split hand: Hit,Stand, or Double Down(h/s/d): " action
			case "$action" in

				"h"|"H")
				  playGo=1
				  sHand=("${sHand[@]}" "$(drawACard)")
	                          echo "Hit"
				  ;;

				"s"|"S")
				  playGo=1
				  endRound=1
				  echo "Stand"
				  ;;

				"d"|"D")
				  if [[ $(($((sbet * 2)) + bet)) -le $money ]]; then # Player can only double if they can afford it
				    playGo=1
				    sbet=$((sbet * 2))
	                            sHand=("${sHand[@]}" "$(drawACard)")
				    sTotal=$(handTotal sHand[@])
         	             	    endRound=1
                        	    echo "Double Down"
				  else
				    echo "Insufficient funds"
				  fi
				  ;;

				*)
				  echo "Incorrect Choice"
				  ;;
			esac
			sleep 1
		done
		fi
	done
	fi

	# Player is done, update the screen
	echo "$(updateDisplay)"
	sleep 1

	# Dealers turn to hit or stand
	if [[ "$sbet" -ge 50 ]]; then
		if [[ "$pTotal" -le 21 ]] || [[ "$sTotal" -le 21 ]]; then
			while [[ "$dTotal" -lt 17 ]] && [[ "$dTotal" -lt "$pTotal" ]]; do # Dealer hits until 17 or victory
				dHand=("${dHand[@]}" "$(drawACard)")
				dTotal=$(handTotal dHand[@])
				echo "$(updateDisplay)"
				sleep 1
			done
		fi
	elif [[ "$pTotal" -le 21 ]]; then
		while [[ "$dTotal" -lt 17 ]] && [[ "$dTotal" -lt "$pTotal" ]]; do
			dHand=("${dHand[@]}" "$(drawACard)")
			dTotal=$(handTotal dHand[@])
			echo "$(updateDisplay)"
			sleep 1
		done
	fi
	sleep 2

	# All bets are in, all cards have been dealt, now determine the winner
	clear
	echo -e "    Final Results\n\n"
	if [[ "$sTotal" -gt 0 ]]; then
		echo -n "First Hand: "
	fi
	if [[ "$pTotal" -gt 21 ]]; then
		echo -e "You busted and lose \$$bet"
		money=$((money - bet))
		losses=$((losses + 1))
	elif [[ "$dTotal" -gt 21 ]]; then
		echo -e "Dealer busted. You win \$$bet"
		money=$((money + bet))
		wins=$((wins + 1))
	elif [[ "$dTotal" -gt "$pTotal" ]]; then
		echo -e "Dealer wins. You lose \$$bet"
		money=$((money - bet))
		losses=$((losses + 1))
	elif [[ "$dTotal" -lt "$pTotal" ]]; then
		if [[ ${#pHand[@]} -eq 2 ]] && [[ "$pTotal" -eq 21 ]]; then
			echo -n "Blackjack! "
			bet=$(($((bet * 3)) / 2))
		fi
		echo -e "You win \$$bet"
		money=$((money + bet))
		wins=$((wins + 1))
	elif [[ "$dTotal" -eq "$pTotal" ]]; then
		echo "Push. You don't win or lose any money."
		pushes=$((pushes + 1))
	fi
	echo -e "\n"
	if [[ "$sTotal" -gt 0 ]]; then
		timesSplit=$((timesSplit + 1))
		echo -n "Split Hand: "
		if [[ "$sTotal" -gt 21 ]]; then
        	        echo -e "You busted and lose \$$sbet"
			money=$((money - sbet))
			losses=$((losses + 1))
	        elif [[ "$dTotal" -gt 21 ]]; then
        	        echo -e "Dealer busted. You win \$$sbet"
			money=$((money + sbet))
			wins=$((wins + 1))
	        elif [[ "$dTotal" -gt "$sTotal" ]]; then
        	        echo -e "Dealer wins. You lose \$$sbet"
			money=$((money - sbet))
			losses=$((losses + 1))
	        elif [[ "$dTotal" -lt "$sTotal" ]]; then
			if [[ ${#sHand[@]} -eq 2 ]] && [[ $sTotal -eq 21 ]]; then
	                        echo -n "Blackjack! "
        	                sbet=$(($((sbet * 3)) / 2))
                	fi
                	echo -e "You win \$$sbet"
			money=$((money + sbet))
			wins=$((wins + 1))
        	elif [[ "$dTotal" -eq "$sTotal" ]]; then
	                echo "Push. You don't win or lose any money."
			pushes=$((pushes + 1))
	        fi
	fi
	echo -e "\n"

	# Ask if player wishes to continue/end of game
	playGo=0
	while [[ "$playGo" -eq 0 ]] && [[ "$money" -ge 50 ]]; do
		read -p "Would you like to continue(Y/n)? " action
		case "$action" in
		  "Y"|"y")
		    playGo=1
		    for hand in "dHand" "pHand" "sHand"; do # Clear the hands for the next round
			unset "${hand[@]}"
		    done
		    ;;

		  "N"|"n")
		    playGo=1
		    quit=0
		    ;;

		  *)
		    echo "Invalid response"
		    ;;

		esac
	done
	if [[ "$money" -lt 50 ]]; then
		echo "You lost too much money!"
		echo -e "\nGAME OVER"
		quit=0
	fi
done
echo -e "\nThanks for playing!"

# END
