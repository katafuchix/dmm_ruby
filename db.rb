# -*- encoding: utf-8 -*-
#gem 'mysql2'
require "rubygems"
require "active_record"
require "yaml"
require "mysql2"

config = YAML.load_file( './database.yml' )
# 環境を切り替える
ActiveRecord::Base.establish_connection(config["db"]["development"])

# テーブルにアクセスするためのクラスを宣言
class TestCom < ActiveRecord::Base
  # テーブル名が命名規則に沿わない場合、
  self.table_name = 'test_com'  # set_table_nameは古いから注意
end

# テーブルにアクセスするためのクラスを宣言
class ItemsMarriedWoman < ActiveRecord::Base
  # テーブル名が命名規則に沿わない場合、
  self.table_name = 'items_married_woman'  # set_table_nameは古いから注意
end

# レコード取得
#p TestCom.all

url = "http://www.dmm.com/lod/akb48/-/detail/=/cid=akb48d15102301/"
b = TestCom.exists?(:link => url)

url = "http://www.dmm.co.jp/digital/videoa/-/detail/=/cid=1sdnm00064/"
b = ItemsMarriedWoman.exists?(:link => url)

p b
if b then
	puts "OK"
else
	puts "Ng"
end

puts File.dirname(__FILE__) 
