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
#  user_id        :integer
#  is_public      :boolean          default(FALSE), not null
#

require 'test_helper'

class RecipesControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
end
