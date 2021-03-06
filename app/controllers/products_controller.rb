class ProductsController < ApplicationController
  skip_before_action :require_login, only: [:index, :show, :category, :create_cart, :browse_by]

  BROWSE = ['All Products', 'Category', 'Merchant']

  def new
    @user = User.find(params[:user_id])
    @categories = Category.all
    @product = Product.new
  end

  def create
    @product = Product.new(product_create_params[:product])
    @categories = Category.all
    @existingcats = ProductCategory.where(product_id: @product.id)

    if @product.save
      @product.photo_url.empty?? @product.update(:photo_url =>  "http://www.spotahome.com/blog/wp-content/plugins/wd-instagram-feed/images/missing.png") : @product.update(:photo_url => params[:product][:photo_url])
      @categories.each do |cat|

        if params[:product][:"#{cat.name}"] == "1" && @existingcats.where(category_id: cat.id).empty?
          @prodcat = ProductCategory.new
          @prodcat.product_id = @product.id
          @prodcat.category_id = cat.id
          @prodcat.save
        end
      end
      redirect_to user_product_path(params[:product][:user_id], @product.id)
    else
      render :new
    end
  end

  def index
    if request.env['PATH_INFO'] == "/users/#{params[:user_id]}/products"
      @user = User.find(params[:user_id])
      @products = Product.where(user_id: params[:user_id])
      if @user.current_user?(current_user)
        render :accountproducts
      else
        @item_exists_in_cart = CartItem.where(session_id: session[:session_id], product_id: params[:id])
        render :merchantproducts
      end
    else
      @browser = BROWSE
      if params[:browse] == BROWSE[1]
        @show = Category.uniq.order(name: :asc)
        render :category
      elsif params[:browse] == BROWSE[2]
        @show = User.where(merchant: true)
        render :merchant
      else
        @show = Product.where(deleted: false, retired: false).order(name: :asc)
      end
    end
  end


  def edit
    @user = User.find(params[:user_id])
    @product = Product.find(params[:id])
    @categories = Category.all
    @existingcats = ProductCategory.where(product_id: @product.id)
    render :new
  end

  def update
    @user = User.find(params[:user_id])
    @product = Product.find(params[:id])
    @categories = Category.all
    @existingcats = ProductCategory.where(product_id: @product.id)


    if @product.save && params[:product] != nil
      @product.update(:name => params[:product][:name])
      @product.update(:price => params[:product][:price])
      @product.update(:inventory => params[:product][:inventory])
      @product.update(:description => params[:product][:description])
      @product.photo_url.empty?? @product.update(:photo_url =>  "http://www.spotahome.com/blog/wp-content/plugins/wd-instagram-feed/images/missing.png") : @product.update(:photo_url => params[:product][:photo_url])
      @product.retired == true ? @product.update(retired: false) : @product.update(retired: true)

      @categories.each do |cat|
        @search = @existingcats.where(category_id: cat.id)
        if params[:product][:"#{cat.name}"] == "1" && @search.empty?
          @prodcat = ProductCategory.new
          @prodcat.product_id = @product.id
          @prodcat.category_id = cat.id
          @prodcat.save
        elsif params[:product][:"#{cat.name}"] == "0" && @search.any?
          ProductCategory.destroy(@search)
        end
      end
      redirect_to user_product_path(params[:user_id],params[:id])
    else
      render :new
    end
  end

  def category
    @browser = BROWSE
    @category = Category.find(params[:id])
    @show = @category.products
    render :categoryproducts
  end

  def destroy
    @user = User.find(params[:user_id])
    @product = Product.find(params[:id])
    @product.destroy
    redirect_to user_products_path(@user)
  end

  def retire
    @user = User.find(params[:user_id])
    @product = Product.find(params[:id])
    @product.retired == false ? @product.update(retired: true) : @product.update(retired: false)
    @product.save
    redirect_to user_products_path(params[:user_id])
    # redirect_to user_products_path(@user)
  end

  def show
    @product = Product.find(params[:id])
    @review = Review.where(product_id: @product.id)
    @cart_item = CartItem.new
    # @cart_items = CartItem.all
    @item_exists_in_cart = CartItem.where(session_id: session[:session_id], product_id: params[:id])
  end

  def new_cats
    @new_cat = Category.new
    @categories = Category.all.order(name: :asc)

  end

  def update_new_cats
    @new_cat = Category.new
    # @categories = Category.all.order(name: :asc)
    @new_cat.update(:name => params[:new])
    if @new_cat.save
      redirect_to root_path
    end
  end


  # def new_cats
  #   @new_cat = Category.new
  #   @categories = Category.all.order(name: :asc)
  # end

  def create_cart
    @cart_item = CartItem.new(cart_params)
    @product = Product.find(params[:id]) || Product.find(@product.id)
    if @cart_item.save
      @cart_item.update(session_id: session[:session_id])
      @cart_item.update(user_id: session[:user_id])
      redirect_to product_path(@product.id), :notice => 'Products added to cart.'
    else
      render :show
    end
  end

  private


  def cart_params
    params.permit(:quantity, :product_id)
  end

  private
  def product_create_params
    params.permit(product: [:name, :price, :description, :inventory, :photo_url, :user_id, :retired, :deleted])
  end
  def product_update_params
    params.permit(product: [:name, :price, :description, :inventory, :photo_url, :user_id, :retired, :deleted])
  end
end
