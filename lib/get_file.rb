#!/usr/bin/env ruby

require 'open-uri'

def get_file(url)
  matched = /^http.*\/([^\/\?]+)\??.*$/.match(url)
  if !matched || matched.size < 2 then
    abort("illegal url #{url}")
  end
  fname = matched[1]
  if File.exist?(fname) then
    ims = File.stat(fname).mtime.rfc2822
  else
    ims = DateTime.new().rfc2822
  end
  $stderr.print "Fetching #{url}...\n"
  begin
    URI.open(url, "rb", "If-Modified-Since" => ims ) do |read_file|
      open(fname, "wb") do |saved_file|
        $stderr.print "Writing #{url} to #{fname}...\n"
        saved_file.write(read_file.read)
      end
    end
  rescue OpenURI::HTTPError => e
    if e.io.status[0] != "304" then
      raise
    end
    $stderr.print "file has not changed.\n"
  end
  return fname
end
