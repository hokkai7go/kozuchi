# -*- encoding : utf-8 -*-
# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  layout 'login' # TODO: リファクタリング
  skip_before_filter :login_required, :only => [:new, :create, :destroy]
  
  # functional test のために残している
  def new
    render :nothing => true
  end

  def create
    if params[:passport] != "1" # utnをつかった簡単ログインでなければ
      self.current_user = User.authenticate(params[:login], params[:password])
    end
    if logged_in? # utnを使った簡単ログインの場合、上記をスキップしてここで自動ログインされる
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(url_for(:controller => 'home', :action => 'index'))
    else
      flash[:error] = "ログインに失敗しました。"
      flash[:login] = params[:login]
      redirect_to root_path
    end
  end

  # シングルログインによるログインユーザー変更
  # ログインしているときだけ使う
  # login だけが指定され、中でSingeLoginデータを参照して認証を行う。
  # 認証された場合、current_user を入れ替える。
  # original_current_user が未設定の場合、変更前に current_user を入れる。
  def update
    raise InvalidParameterError unless params[:login]
    if original_user && original_user.login == params[:login]
      self.current_user = original_user
      self.original_user = nil
      redirect_to home_path
      return
    end

    single_login = current_user.single_logins.find_by_login(params[:login])
    raise IllegalStateError unless single_login
    if !single_login.active?
      flash[:errors] = ["#{single_login.login}さんへのシングルログイン設定は無効です。ログインID、パスワードが正しいか確認してください。"]
      redirect_to home_path # TODO:
      return
    end
    self.original_user ||= self.current_user
    self.current_user = User.find_by_login(single_login.login) # TODO: きれいに
    redirect_to home_path
  end


  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(root_path)
  end
end
