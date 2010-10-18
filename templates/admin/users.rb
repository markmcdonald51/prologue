generate(:controller, "admin/users index new create edit update destroy")

inject_into_file 'config/routes.rb', :after => "devise_for :users\n" do
<<-'FILE'
  namespace "admin" do
    resources :users
  end
FILE
end

inject_into_file 'app/controllers/admin/users_controller.rb', :after => "def index\n" do
<<-'FILE'
    @sortable = SortIndex::Sortable.new(params, INDEX_SORT)
    @users = User.paginate :page => params[:page], :order => @sortable.order, :per_page => 2
FILE
end

inject_into_file 'app/controllers/admin/users_controller.rb', :after => "def new\n" do
<<-'FILE'
    @user = User.new
FILE
end

inject_into_file 'app/controllers/admin/users_controller.rb', :after => "def create\n" do
<<-'FILE'
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "User created!"
      redirect_to admin_users_url
    else
      render :action => 'new'
    end
FILE
end

inject_into_file 'app/controllers/admin/users_controller.rb', :after => "def update\n" do
<<-'FILE'
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated #{@user.name}."
      redirect_to admin_users_url
    else
      render :action => 'edit'
    end
FILE
end

inject_into_file 'app/controllers/admin/users_controller.rb', :after => "def destroy\n" do
<<-'FILE'
    @user.destroy
    flash[:notice] = "User deleted."
    redirect_to admin_users_url
FILE
end

gsub_file 'app/controllers/admin/users_controller.rb', /ApplicationController/, 'Admin::BaseController'

inject_into_file 'app/controllers/admin/users_controller.rb', :after => "class Admin::UsersController < Admin::BaseController\n" do
<<-'FILE'
  before_filter :find_user, :only => [:edit, :update, :destroy]
  
  INDEX_SORT = SortIndex::Config.new(
    {'name' => 'name'},
    {
      'email' => 'email',
      'login' => 'login',
      'roles_mask' => 'roles_mask',
      'last_login_at' => 'last_login_at'
    }
    #, optionally SortIndex::SORT_KEY_ASC
  )
  
  def find_user
    @user = User.find(params[:id])
  end
  
FILE
end

create_file 'app/views/admin/users/_form.html.haml' do
<<-'FILE'
- form_for([:admin, @user])  do |f|
  .form_errors
    = f.error_messages
  %fieldset#user_form
    .form_row
      = f.label :name
      = f.text_field :name
    .form_row
      = f.label :email
      = f.text_field :email
    .form_row
      = f.label :password
      = f.password_field :password
    .form_row
      = f.label :password_confirmation
      = f.password_field :password_confirmation
    .form_row.form_row_button
      = f.submit "Save"
FILE
end

create_file 'app/views/admin/users/edit.html.haml' do
<<-'FILE'
= render :partial => "form"
FILE
end

create_file 'app/views/admin/users/new.html.haml' do
<<-'FILE'
= render :partial => "form"
FILE
end

create_file 'app/views/admin/users/index.html.haml' do
<<-FILE
- if !@users.blank?
  %table
    %thead
      %tr
        %th= @sortable.header_link('name', 'Name')
        %th= @sortable.header_link('email', 'Email')
        %th
        %th
    %tbody
      - for user in @users
        %tr
          %td= user.name
          %td= user.email
          %td= link_to "Edit", edit_admin_user_path(user), :class => 'edit_link'
          %td
            - if user.id != current_user.id
              = link_to "Delete", admin_user_path(user), :confirm => t('forms.confirm'), :method => :delete, :class => 'delete_link'
            - else
              That's you!
  = will_paginate @users
- else
  %p No users
FILE
end

