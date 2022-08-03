#!/bin/bash
result=$(/usr/sbin/lsof -iTCP:25565 -sTCP:ESTABLISHED | tail -n +2 | wc -l)
echo -n $result > players.txt
while [ 1 -gt 0 ]; do
        result=$(/usr/sbin/lsof -iTCP:25565 -sTCP:ESTABLISHED | tail -n +2 | wc -l)
        previousPlayers=$(cat players.txt)
        echo "Current players: $result, players 30 seconds ago: $previousPlayers"
        if [ $result -gt $previousPlayers ]
        then
                #logged in
                sleep 5 #(give the log a chance to get written to)
                username=$(grep "logged in" /home/ec2-user/valhesia/logs/latest.log  | tail -n 1 | cut -d: -f4 | cut -d"[" -f1)
                ip=$(grep "logged in" /home/ec2-user/valhesia/logs/latest.log  | tail -n 1 | cut -d: -f4 | cut -d"[" -f2)

                message="$result new players have joined. Username is probably $username, and they connected from $ip"
                echo $message
                aws sns publish --message "$message" --phone-number +1REDACTED
                echo -n $result > players.txt
        fi
        if [ $result -lt $previousPlayers ]
        then
                #lost connection
                sleep 5 #(give the log a chance to get written to)
                username=$(grep "lost connection" /home/ec2-user/valhesia/logs/latest.log  | tail -n 1 | cut -d: -f4 | cut -d" " -f2)
                message="Someone (named '$username') has left the server. There are now $result players playing."
                echo $message
                aws sns publish --message "$message" --phone-number +1REDACTED
                echo -n $result > players.txt
        fi
        sleep 30
done
