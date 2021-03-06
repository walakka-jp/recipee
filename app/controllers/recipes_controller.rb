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

class RecipesController < ApplicationController
  before_action :set_recipe, only: [:edit, :update, :destroy, :show, :star, :unstar]
  before_action :set_is_public, only: [:index, :show, :starred_index]
  before_action :is_self_owned, only: [:edit, :update, :destroy]
  before_action :is_self_owned_or_public, only: [:show]
  skip_before_action :require_login, only: [:show, :index]

  def index
    @q = Recipe.ransack(params[:q])
    if @is_public || !current_user
      # みんなのレシピ
      @recipes = @q.result(distinct: true).where(is_public: true)
      @recipes = @recipes.where.not(user_id: current_user.id) if current_user
    else
      # マイレシピ
      @recipes = @q.result(distinct: true).where(user_id: current_user.id)
      # 検索結果ではないばあい、お気に入り登録したレシピを追加（重複は排除）
      unless params[:q].present?
        @recipes = array_to_relations(
          [@recipes,  current_user.find_voted_items], Recipe
        )
      end
    end
    set_all_tags(@recipes)
    @recipes = @recipes.page(params[:page])
    @recipes = @recipes.tagged_with(params[:tag]) if params[:tag]
  end

  def starred_index
    @recipes = array_to_relations([current_user.find_voted_items], Recipe)
    set_all_tags(@recipes)
    @recipes = @recipes.page(params[:page])
  end

  def new
    @recipe = current_user.recipes.new
    @recipe.recipe_ingredients.build.row_order = 1 # new ではなく build
    @recipe.recipe_steps.build.row_order = 1 # new ではなく build
  end

  def create
    @recipe = current_user.recipes.new(recipe_params)
    if @recipe.save
        flash[:notice] = "レシピを保存しました。"
        redirect_to @recipe
    else
        flash[:alert] = "レシピの保存に失敗しました。"
        render :new
    end
  end

  def edit
  end

  def show
  end

  def destroy
    if @recipe.destroy
      flash[:notice] = "レシピを削除しました。"
      redirect_to root_path
    else
      flash[:alert] = "レシピの削除に失敗しました。"
      # えっと？
    end
  end

  def clip
    url = params[:clip_url]
    # view_context経由でヘルパーメソッドの呼び出し
    clipper = view_context.create_clipper(url)
    if clipper.present?
      @recipe = current_user.recipes.new(clipper.recipe_params)
      if @recipe.save
          flash[:notice] = "外部レシピを取得して保存しました。"
          redirect_to @recipe
      else
          flash[:alert] = "外部レシピを取得しましたが、保存に失敗しました。"
          render :new
      end
    else
      flash[:alert] = "外部レシピデータが取得できませんでした。URLを確認してください。"
      redirect_to new_recipe_path
    end
  end

  def update
    if @recipe.update(recipe_params)
      flash[:notice] = "レシピを更新しました。"
      redirect_to @recipe
    else
      flash[:alert] = "レシピの更新に失敗しました。"
      render :edit
    end
  end

  def star
    @recipe.liked_by current_user if current_user
  end

  def unstar
    @recipe.unliked_by current_user if current_user
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:id])
  end

  def set_is_public
    @is_public = (params.try(:[], :recipe).try(:[], :is_public)) == "true"
  end

  def set_all_tags(recipes)
    @tags = Set.new
    recipes.each { |recipe| @tags.merge(recipe.tag_list) }
  end

  def is_self_owned
    redirect_to root_path unless @recipe.user_id == current_user.id
  end

  def is_self_owned_or_public
    redirect_to root_path unless @recipe.is_public || @recipe.user_id == current_user.id
  end

  # ActiveRecord::Relation と 配列 を結合して Relation として返す
  # acts_as_votable のメソッドが配列を返してくるため、苦肉の策
  def array_to_relations relations, klass
    ids = Array.new
    relations.each { |rel|
      ids.concat rel.map{ |r| r.id }
    }
    klass.where(id: ids.uniq)
  end

  def recipe_params
    params.require(:recipe).permit(:id, :user_id, :title, :author_name, :ref_url,
      :main_photo_url, :description, :servings_for,
      :image, :image_cache, :remove_image, :clip_url, :tag_list,
      :tag, :is_public,
      recipe_ingredients_attributes: [:id, :name, :quantity_for,
        :order, :row_order, :_destroy],
      recipe_steps_attributes: [:id, :text, :photo_url, :position, :row_order,
        :image, :remove_image, :image_cache, :_destroy])
  end
end
