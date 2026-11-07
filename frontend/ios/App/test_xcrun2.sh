app_id="com.loveworks.app"

output=$(xcrun simctl launch 6206DF0A-CA53-476C-9DAD-AC6260B032AD $app_id 2>&1)
echo "Output: $output"
exit_code=$?
echo "Exit: $exit_code"
