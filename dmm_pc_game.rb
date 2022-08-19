# _*_ coding: utf-8 _*_
require 'anemone'
require 'nokogiri'
require 'kconv'
require "active_record"
require "yaml"
require "mysql2"
require './ItemsPcGame.rb' 

config = YAML.load_file( './database.yml' )
# 環境を切り替える
ActiveRecord::Base.establish_connection(config["db"]["development"])

# タイトル
def getTitle(url)
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			begin
				return  doc.xpath("//h1[@id=\"title\"][1]").text
			rescue
				return ""
			end
		end
	end
end

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
				return  doc.xpath("//div[@class=\"mg-b20 lh4\"]").text.strip
			rescue
				return ""
			end
		end
	end
end

# 
def getInfo(url)
	title = ""
	package = ""
	description = ""
	
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			begin
				title = doc.xpath("//h1[@id=\"title\"][1]").text.strip
			rescue
			end
			
			begin
				package = doc.xpath("//*[@name=\"package-image\"][1]").attribute("href")
			rescue
			end
			
			begin
				description = doc.xpath("//div[@class=\"mg-b20 lh4\"]").text.strip
			rescue
			end
		end
	end
	return title, package, description
end


def getStartDate(url)
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			begin
				#return  doc.xpath("//*[@id=\"mu\"]/div[1]/table/tbody/tr/td[1]/div[4]/p").text
				return  doc.xpath("//table[@class=\"mg-b20\"]/tr[3]/td[1]").text
			rescue
				return ""
			end
		end
	end
end

def getEndDate(url)
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			begin
				#return  doc.xpath("//*[@id=\"mu\"]/div[1]/table/tbody/tr/td[1]/div[4]/p").text
				return  doc.xpath("//table[@class=\"mg-b20\"]/tr[4]/td[1]").text
			rescue
				return ""
			end
		end
	end
end

urls = []
urls.push("http://www.dmm.co.jp/dc/pcgame/-/list/=/sort=date/")
#urls.push("http://www.dmm.co.jp/dc/pcgame/-/list/=/sort=date/page=6/");

#r = rand(1178) + 1
#url = "http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=1039/sort=ranking/page=" + r.to_s + "/"
#urls.push(url)

#for num in 1...235 do
#  url = "http://www.dmm.co.jp/dc/pcgame/-/list/=/sort=date/page=" + num.to_s + "/"
  #puts url
#  urls.push(url)
#end

opts = {
  :depth_limit => 0,
  :delay => 1
}

Anemone.crawl(urls, opts) do |anemone|
  anemone.on_every_page do |page|
    doc = Nokogiri::HTML.parse(page.body.toutf8)
	
	items = doc.xpath("//*[@id=\"list\"]/li")
	
    items.each do |item|
		#puts item
		site = "http://www.dmm.co.jp/dc/pcgame/"
		url = ""
		url = "http://www.dmm.co.jp" + item.xpath("div[1]/p[@class=\"tmb\"]/a").attribute("href")
		#url = url.strip
		begin
			url = url.to_s
		rescue
		end
		puts url
		
		b = ItemsPcGame.exists?(:link => url)
		puts b
		if b then
			next
		end
		
		begin
			# title
			#title = getTitle(url)
			
			# price
			price = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"price\"]").text
			off = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"price\"]/span").text
			# rate
			rate = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"rate\"]/span/span").text
			puts rate
			# actress
			actress = item.xpath("div[1]/p[@class=\"sublink\"]/span/a").text
			puts actress
			
			#package = getImage(url)
			#description = getDescription(url)
			#puts getStartDate(url)
			#puts getEndDate(url)
			title, package, description = getInfo(url)
			puts title
			puts package
			puts description
			rdate = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
			#puts rdate

			@item = ItemsPcGame.new(:site=>site, :link => url, :title=>title,
															:package=>package, 
															:price=>price, :off=>off,
															:description=>description,
															:rate=>rate,
															:actress=>actress, :rdate=>rdate)
			begin
				ItemsPcGame.transaction do
					@item.save!
				end
			rescue
			end
		end
	end
  end
end


