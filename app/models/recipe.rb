# == Schema Information
#
# Table name: recipes
#
#  id             :integer          not null, primary key
#  title          :string
#  author_name    :string
#  ref_url        :string
#  main_photo_url :string
#  description    :string
#  servings_for   :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  image          :string
#

class Recipe < ActiveRecord::Base
    has_many :recipe_ingredients
    accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true
    
    has_many :recipe_steps
    accepts_nested_attributes_for :recipe_steps, allow_destroy: true
   
    mount_uploader :image, ImageUploader

    validates :title, presence: true, length: {minimum: 1, maximum: 50}
end