# _*_ coding: utf-8 _*_
require 'anemone'
require 'nokogiri'
require 'kconv'
require "active_record"
require "yaml"
require "mysql2"
require './ItemsDvdMono.rb' 

config = YAML.load_file( './database.yml' )
# 環境を切り替える
ActiveRecord::Base.establish_connection(config["db"]["development"])

# パッケージ画像
def getImage(url)
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			begin
				return  doc.xpath("//*[@name=\"package-image\"][1]").attribute("href")
			rescue
				return ""
			end
		end
	end
end

# 商品説明
def getDescription(url)
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			begin
				#return  doc.xpath("//*[@id=\"mu\"]/div[1]/table/tbody/tr/td[1]/div[4]/p").text
				return  doc.xpath("//p[@class=\"mg-b20\"]").text.strip
			rescue
				return ""
			end
		end
	end
end

urls = []
urls.push("http://www.dmm.co.jp/mono/dvd/-/special/=/id=79/")

for num in 1..20 do
  url = "http://www.dmm.co.jp/mono/dvd/-/special/=/id=79/page=" + num.to_s + "/"
  urls.push(url)
end

#for num in 1..59 do
#  url = "http://www.dmm.co.jp/mono/dvd/-/special/=/id=79/page=" + num.to_s + "/"
#  urls.push(url)
#end

opts = {
  :depth_limit => 0,
  :delay => 1
}

Anemone.crawl(urls, opts) do |anemone|
  anemone.on_every_page do |page|
    doc = Nokogiri::HTML.parse(page.body.toutf8)
	
	items = doc.xpath("//table[@class=\"tbl-sm147\"]")
	
    items.each do |item|
		trs =  item.xpath("tr")
			trs.each do |tr|
				tds =  tr.xpath("td")
				tds.each do |td|
					#puts td
					
					ink = ""
					link = "http://www.dmm.co.jp" + td.xpath("div[1]/a").attribute("href")
					site = "http://www.dmm.co.jp/mono/dvd/"
					
					begin
						link = link.to_s
					rescue
					end
					
					b = ItemsDvdMono.exists?(:link => link)
					if b then
						next
					end
					
					title = ""
					package = ""
					description = ""
					maker = ""
					actress = ""
					content = ""
					puts link
					puts td.xpath("div[1]/a").attribute("href")
					puts td.xpath("div[1]/a/img").attribute("src")
					
					puts td.xpath("div[2]/p[1]/a").text
					puts td.xpath("div[2]/p[2]").text
					puts td.xpath("div[2]/div[3]").text
					puts td.xpath("div[2]/div[1]/a").text
					puts td.xpath("div[2]/div[2]/a").text
					
					title = td.xpath("div[2]/p[1]/a").text
					price = td.xpath("div[2]/p[2]").text
					description = td.xpath("div[2]/div[3]").text
					maker = td.xpath("div[2]/div[1]/a").text
					actress =  td.xpath("div[2]/div[2]/a").text
					
					package = getImage(link)
					puts package
					
					begin
						description = description.strip
					rescue
					end
					
					content = getDescription(link)
					rdate = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
					
					@item = ItemsDvdMono.new(:site=>site, :link => link, :title=>title,
																			:package=>package, :price=>price, :description=>description,
																			:content => content, 
																			:maker=>maker, :actress=>actress, :rdate=>rdate)
					begin
						ItemsDvdMono.transaction do
							@item.save!
						end
					rescue
					end
					
					puts "####"
				end
			end
		end
  end
end


