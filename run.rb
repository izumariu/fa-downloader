#!/usr/bin/env ruby

Dir.chdir File.dirname __FILE__

require "net/http"
require "nokogiri"
require "io/console"
load 'falib.rb'

$USER = ARGV[0]
ARGV.clear

$USER||abort("USAGE: ruby #{__FILE__} <user>")

resp = Net::HTTP.get_response URI FALib.urlencode FALib.RelativePath "/user/#{$USER}/"
abort("Response code was HTTP #{resp.code}") if resp.code.to_i!=200
resp = Nokogiri::HTML resp.body

resp.to_s.match(%r{<b>System Message</b>})&&abort([
  "+"*("SYSTEM MESSAGE".length+4),
  "+ SYSTEM MESSAGE +",
  "+"*("SYSTEM MESSAGE".length+4),
  FALib.extract_sysmsg(resp)
].join("\n"))

$USER = FALib.extract_username_from_userpage(resp)
$user = $USER.downcase.gsub(/[^A-Za-z0-9\-]/,"_")
puts "Extracting pictures of ~#{$USER}'s gallery."

Dir.mkdir("pics") rescue nil
Dir.mkdir("pics/#{$user}") rescue nil

pagenum = 1

loop do

  resp = Net::HTTP.get_response URI FALib.urlencode FALib.RelativePath "/gallery/#{$USER}/#{pagenum}/?perpage=72"
  abort("Response code was HTTP #{resp.code}") if resp.code.to_i!=200
  resp.body.match(%r{<i>There are no submissions to list</i>})&&break
  puts "Page #{pagenum}"
  resp = Nokogiri::HTML resp.body

  links = FALib.extract_absolute_gallery_links(resp)

  for link in links

    resp2 = Net::HTTP.get_response URI FALib.urlencode link
    resp2.body.match(%r{<img[^<>]*id="submissionImg"[^<>]*>})
    $&||(puts("Error, skipping image");puts;next)
    maxres = "http:#{ $&.match(%r{data-fullview-src="([^"]+)"})[-1] }"
    filename = maxres.split("/")[-1][%r{^\d+\.(.+)$},1][/^#{$user}_(.+)$/,1]

    File.exists?("pics/#{$user}/#{filename}")&&(puts("File #{maxres} exists, skipping");puts;next)

    content = Net::HTTP.get_response URI FALib.urlencode maxres
    content.code.to_i==200||(puts("GET Content returned HTTP #{content.code}, skipping image");puts;next)

    File.write("pics/#{$user}/#{filename}",content.body)
    puts "#{maxres} => pics/#{$user}/#{filename}"

    puts
    "".match(/./) # clear $&
  end

  puts "+"*IO.console.winsize[1]

  pagenum += 1

end
