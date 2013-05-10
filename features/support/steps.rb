require "shellwords"

require "hq/sms-global/balance-check/script"

Given /^a file "(.*?)":$/ do
	|file_name, file_contents|

	File.open file_name, "w" do
		|file_io|

		file_contents =
			file_contents.gsub "${server-url}", $web_url

		file_io.write file_contents

	end

end

Given /^that the balance is (\d+)$/ do
	|balance_str|

	$balance = balance_str.to_f

end

When /^I run the script with args:$/ do
	|args_str|

	@script = HQ::SmsGlobal::BalanceCheck::Script.new
	@script.args = Shellwords.split args_str

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
