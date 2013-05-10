require "hq/tools/check-script"
require "hq/tools/escape"
require "hq/tools/getopt"

require "net/http"

require "xml"

module HQ
module SmsGlobal
module BalanceCheck

class Script < Tools::CheckScript

	include Tools::Escape

	def process_args

		@opts, @args =
			Tools::Getopt.process @args, [

				{ :name => :config,
					:required => true },

				{ :name => :account,
					:required => true },

				{ :name => :warning,
					:convert => :to_f,
					:required => true },

				{ :name => :critical,
					:convert => :to_f,
					:required => true },

			]

		raise "Extra args" unless @args.empty?

		@name = "SMS Global #{@opts[:account]}"

	end

	def prepare

		load_config

	end

	def load_config

		config_doc =
			XML::Document.file @opts[:config]

		@config_elem =
			config_doc.root

		@server_elem =
			@config_elem.find_first "server"

		@account_elem =
			@config_elem.find_first "account [
				@name = #{esc_xp @opts[:account]}
			]"

	end

	def perform_checks

		url =
			URI.parse "#{@server_elem["url"]}/balance-api.php"

		url.query =
			URI.encode_www_form({
				"user" => @account_elem["username"],
				"password" => @account_elem["password"],
			})

		Net::HTTP.start url.host, url.port do
			|http|


			request = Net::HTTP::Get.new "#{url.path}?#{url.query}"

			response = http.request request

			raise "Error 1" \
				unless response.code == "200"

			raise "Error 2" \
				unless response.body =~ /^BALANCE: ([^;]+); USER: (.+)$/

			actual_balance = $1.to_f

			if actual_balance < @opts[:critical]

				critical "%s credits (critical is %s)" % [
					actual_balance.to_i,
					@opts[:critical].to_i,
				]

			elsif actual_balance < @opts[:warning]

				warning "%s credits (warning is %s)" % [
					actual_balance.to_i,
					@opts[:warning].to_i,
				]

			else

				message "%s credits" % [
					actual_balance.to_i,
				]

			end

		end

	end

end

end
end
end
