require "shellwords"

require "hq/sms-global/balance-check/script"

Given /^the balance is (\d+)$/ do
	|balance_str|

	$balance = balance_str.to_f

end

Given /^the server is offline$/ do

	$status = :offline

end

When /^I run the script with "(.+)"$/ do
	|args_file|

	@script = HQ::SmsGlobal::BalanceCheck::Script.new
	@script.args = Shellwords.split File.read(args_file)

	@script.stdout = StringIO.new
	@script.stderr = StringIO.new

	@script.main

end

Then /^the status should be (\d+)$/ do
	|status_str|
	@script.status.should == status_str.to_i
end

Then /^the output should be:$/ do
	|expected_output|
	@script.stdout.string.strip.should == expected_output
end
