# _*_ coding: utf-8 _*_
require 'anemone'
require 'nokogiri'
require 'kconv'
require "active_record"
require "yaml"
require "mysql2"
require './ItemsComic.rb' 

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
				description = doc.xpath("//div[@class=\"m-boxDetailProduct__info__story\"]").text.strip
			rescue
			end
		end
	end
	return title, package, description
end


urls = []
urls.push("http://book.dmm.co.jp/list/comic/?floor=Abook&type=single&sort=date")
urls.push("http://book.dmm.co.jp/list/comic/?floor=Abook&sort=date&type=volume");
urls.push("http://book.dmm.co.jp/list/comic/?floor=Abook&sort=date&type=magazine")

r = rand(772) + 1
url = "http://book.dmm.co.jp/list/comic/?floor=Abook&type=single&sort=date&page=" + r.to_s + "/"
urls.push(url)

r = rand(342) + 1
url = "http://book.dmm.co.jp/list/comic/?floor=Abook&sort=date&type=volume&page=" + r.to_s + "/"
urls.push(url)

#for num in 1...4 do
#  url = "http://book.dmm.co.jp/list/comic/?floor=Abook&sort=date&type=magazine&page=" + num.to_s
  #puts url
#  urls.push(url)
#end

#for num in 1...772 do
#  url = "http://book.dmm.co.jp/list/comic/?floor=Abook&type=single&sort=date&page=" + num.to_s
  #puts url
#  urls.push(url)
#end

#for num in 1...342 do
#  url = "http://book.dmm.co.jp/list/comic/?floor=Abook&sort=date&type=volume&page=" + num.to_s
 # puts url
#  urls.push(url)
#end

opts = {
  :depth_limit => 0,
  :delay => 1
}

Anemone.crawl(urls, opts) do |anemone|
  anemone.on_every_page do |page|
  puts page.url
    doc = Nokogiri::HTML.parse(page.body.toutf8)
	
	items = doc.xpath("//div[@class=\"m-boxListBookProduct\"]/ul[1]/li")
	
    items.each do |item|
		#puts item
		site = "http://book.dmm.co.jp/"
		url = ""
		url =  item.xpath("div[@class=\"m-boxListBookProductTmb\"]/a").attribute("href")
		#url = url.strip
		begin
			url = url.to_s
		rescue
		end
		puts url
		
		b = ItemsComic.exists?(:link => url)
		puts b
		if b then
			next
		end
		
		begin
			t = item.xpath("div[@class=\"m-boxListGenreIco m-boxListGenreIco--large\"]/span[1]").text.strip
			puts t
			
			# title
			title = item.xpath("div[@class=\"m-boxListBookProductTmb\"]/a[1]/span[1]/img[1]").attribute("alt")
			puts title
			
			# price
			price = item.xpath("div[@class=\"m-boxListBookProductTmb\"]/div[@class=\"m-boxListBookProductTmb__itemSubInfo\"]/ul[1]/li[2]").text.strip
			if price=="" then
				price = item.xpath("div[@class=\"m-boxListBookProductTmb\"]/div[@class=\"m-boxListBookProductTmb__itemSubInfo\"]/ul[1]/li[1]").text.strip
			end
			puts price
			
			author= item.xpath("div[@class=\"m-boxListBookProductTmb\"]/span[@class=\"m-boxListBookProductTmb__linkAuthor\"]/a[1]").text.strip
			puts author
			
			#off = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"price\"]/span").text
			# rate
			#rate = item.xpath("div[1]/div[@class=\"value\"]/p[@class=\"rate\"]/span/span").text
			#puts rate
			# actress
			#actress = item.xpath("div[1]/p[@class=\"sublink\"]/span/a").text
			#puts actress
			
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

			@item = ItemsComic.new(:site=>site, :link => url, :title=>title, :genre=>t,
															:package=>package, 
															:price=>price, 
															:description=>description,
															:author=>author, :rdate=>rdate)
			begin
				ItemsComic.transaction do
					@item.save!
				end
			rescue
			end
		end
	end
  end
end


