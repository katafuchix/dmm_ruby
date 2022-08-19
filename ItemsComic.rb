# -*- encoding: utf-8 -*-
require "rubygems"
require "active_record"

# テーブルにアクセスするためのクラスを宣言
class ItemsComic < ActiveRecord::Base
  # テーブル名が命名規則に沿わない場合、
  self.table_name = 'items_comic'  # set_table_nameは古いから注意
end