# _*_ coding: utf-8 _*_
require 'anemone'
require 'nokogiri'
require 'kconv'
require "active_record"
require "yaml"
require "mysql2"
require './ItemsDigitalVideoaLori.rb' 

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
puts url
	title = ""
	package = ""
	description = ""
	release_date = "";
	
	opts = {:depth_limit => 0, :delay => 1}
	Anemone.crawl(url, opts) do |anemone|
		anemone.on_every_page do |page|
			doc = Nokogiri::HTML.parse(page.body.toutf8)
			#puts page.body.toutf8
			begin
				title = doc.xpath("//h1[@id=\"title\"][1]").text
			rescue
			end
			
			begin
				package = doc.xpath("//*[@name=\"package-image\"][1]").attribute("href")
				#puts package
			rescue
			end
			
			begin
				description = doc.xpath("//div[@class=\"mg-b20 lh4\"]").text.strip
			rescue
			end
			
			begin
				release_date = doc.xpath("//table[@class=\"mg-b20\"]/tr[2]/td[2]").text
				puts release_date
			rescue
			end
			
		end
	end
	return title, package, description, release_date
end

urls = []
urls.push("http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=2008/sort=ranking/")
urls.push("http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=2008/sort=date/");

for num in 1..50 do
  url = "http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=2008/sort=date/page=" + num.to_s + "/"
  #puts url
  urls.push(url)
end

for num in 1..50 do
  url = "http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=2008/sort=ranking/page=" + num.to_s + "/"
  #puts url
  urls.push(url)
end

#for num in 1..30 do
#	r = rand(1178) + 1
#	url = "http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=2008/sort=ranking/page" + r.to_s + "/"
#	urls.push(url)
#end 

#for num in 1..312 do
#  url = "http://www.dmm.co.jp/digital/videoa/-/list/=/article=keyword/id=2008/sort=ranking/page=" + num.to_s + "/"
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
		site = "http://www.dmm.co.jp/digital/videoa/"
		url = ""
		url =  item.xpath("div[1]/p[@class=\"tmb\"]/a").attribute("href")
		begin
			url = url.to_s
		rescue
		end
		puts url
		
		b = ItemsDigitalVideoaLori.exists?(:link => url)
		if b then
			next
		end
		
		begin
			# title
			#title = getTitle(url)
			
			# price
			price = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"price\"]").text
			puts price
			
			off = ""
			begin
				off = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"price\"]/span").text.strip
				puts off
			rescue
			end
			
			# actress
			actress = item.xpath("div[1]/p[@class=\"sublink\"]/span/a").text
			puts actress
			
			#package = getImage(url)
			#description = getDescription(url)
			#puts getStartDate(url)
			#puts getEndDate(url)
			title, package, description, release_date = getInfo(url)
			puts title
			puts package
			puts description
			puts release_date
			
			if package=="" then
				next
			end
			
			rdate = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")
			#puts rdate
				
			@item = ItemsDigitalVideoaLori.new(:site=>site, :link => url, :title=>title,
															:package=>package, :price=>price, :off=>off, :description=>description,
															:actress=>actress, :release_date=>release_date, 
															:rdate=>rdate)
			begin
				ItemsDigitalVideoaLori.transaction do
					@item.save!
				end
			rescue
			end
		
		rescue
		end
		
	end
  end
end


