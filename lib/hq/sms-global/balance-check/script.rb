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

				{ :name => :cache_warning,
					:convert => :to_i },

				{ :name => :cache_critical,
					:convert => :to_i },

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

		@cache_elem =
			@config_elem.find_first "cache"

		@account_elem =
			@config_elem.find_first "account [
				@name = #{esc_xp @opts[:account]}
			]"

	end

	def perform_checks

		used_cache = false

		begin

			get_balance_from_server

		rescue => exception

			raise exception \
				unless @cache_elem

			read_cache

			used_cache = true

		end

		# report balance

		if @actual_balance < @opts[:critical]

			critical "%s credits (critical is %s)" % [
				@actual_balance.to_i,
				@opts[:critical].to_i,
			]

		elsif @actual_balance < @opts[:warning]

			warning "%s credits (warning is %s)" % [
				@actual_balance.to_i,
				@opts[:warning].to_i,
			]

		else

			message "%s credits" % [
				@actual_balance.to_i,
			]

		end

		# report cache usage

		if used_cache

			if @opts[:cache_critical] \
				&& @cache_age >= @opts[:cache_critical]

				critical "last check %s seconds ago (critical is %s)" % [
					@cache_age,
					@opts[:cache_critical]
				]

			elsif @opts[:cache_warning] \
				&& @cache_age >= @opts[:cache_warning]

				warning "last check %s seconds ago (warning is %s)" % [
					@cache_age,
					@opts[:cache_warning]
				]

			else

				message "last check #{@cache_age} seconds ago"

			end

		end

		write_cache

	end

	def get_balance_from_server

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

			@actual_balance =
				$1.to_f

		end

	end

	def read_cache

		cache_path = "%s/%s.yaml" % [
			@cache_elem["dir"],
			@opts[:account],
		]

		cache_data =
			YAML.load_file cache_path

		@actual_balance =
			cache_data["balance"]

		@cache_age =
			(Time.now - cache_data["timestamp"]).to_i

	end

	def write_cache

		return unless @cache_elem

		cache_data = {
			"balance" => @actual_balance,
			"timestamp" => Time.now,
		}

		cache_path = "%s/%s.yaml" % [
			@cache_elem["dir"],
			@opts[:account],
		]

		File.open "#{cache_path}.new", "w" do
			|cache_io|

			cache_io.write YAML.dump cache_data

		end

		FileUtils.mv "#{cache_path}.new", cache_path

	end

end

end
end
end
