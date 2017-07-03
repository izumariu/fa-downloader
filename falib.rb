module FALib

  Baseurl = "https://www.furaffinity.net"

  def self.RelativePath(path)
    [Baseurl,path].join("/").gsub(%r{(?<!https:)/+},"/")
  end

  def self.extract_sysmsg(resp)
    resp.css('td.alt1').first.children.select{|i|i.name=="b"}.map(&:to_s).join.gsub(%r{</?[^<>]+>},"")
  end

  def self.extract_username_from_gallery(resp) # DEPRECATED
    resp.css('div.user-name').children.select{|i|i.name=="span"}.first.children.first.to_s.match(%r{^~([A-Za-z0-9]+)'s Gallery})[1]
  end

  def self.extract_username_from_userpage(resp)
    resp.css('td.addpad.lead').children.select{|i|i.name=="b"}[0].children[0].to_s.match(/^.(.*)/)[1]
  end

  def self.extract_relative_gallery_links(resp)
    resp.css('figure.t-image').map{|i|i.children[1].children[0].children[0].attributes["href"].value}
  end

  def self.extract_absolute_gallery_links(resp)
    extract_relative_gallery_links(resp).map{|i|RelativePath(i)}
  end

  def self.urlencode(url)
    url.bytes.map(&:chr).map{|i| i.inspect[/\\x[A-F0-9]{2}|[\[\]\(\)\{\}]/] ? ("%%%02x" % i.ord).upcase : i }.join
  end

end
