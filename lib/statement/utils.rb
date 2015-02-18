require 'uri'

module Utils
  def self.absolute_link(url, link)
    return link if link =~ /^http/
    ("http://"+URI.parse(url).host + "/"+link).to_s
  end

  def self.remove_generic_urls!(results)
    results.reject{|r| URI.parse(URI.escape(r[:url])).path == '/news/' or URI.parse(URI.escape(r[:url])).path == '/news'}
  end
end
