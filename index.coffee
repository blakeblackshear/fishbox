smtpserver = require 'simplesmtp'
MailParser = require('mailparser').MailParser
fse = require 'fs-extra'
fs = require 'fs'
http = require 'http'
url = require 'url'

store_email = (email) ->
  email.to.map (address) ->
    address.address.split('@').shift()
  .forEach (recipient) ->
    fse.outputJson "mail/#{recipient}/email.json",
      received: email.date 
      subject: email.subject
      text: email.text
      html: email.html
    , (err) ->
      if err?
        console.error err

smtpserver.createSimpleServer { SMTPBanner:'Fishbox' }, (req) ->
  console.log "Received email from: #{JSON.stringify(req.from)}"
  mailparser = new MailParser()
  mailparser.on 'end', store_email
  req.pipe mailparser
  req.accept()
.listen(25)

http.createServer (req, res) ->
  uri = url.parse(req.url).pathname

  fs.exists "mail/#{uri}", (exists) ->
    if not exists
      res.writeHead 404
      res.write '404'
      res.end()
      return

    fs.readFile "mail/#{uri}/email.json", 'utf8', (err, data) ->
      if err?
        res.writeHead 500
        res.write err
        res.end()
      res.writeHead 200, {'Content-Type': 'application/json'}
      res.write data
      res.end()

.listen(3000)

