# -*- encoding : utf-8 -*-
module User::Friend
  def self.included(base)
    base.has_many :friend_requests, :class_name => "Friend::Request", :dependent => :destroy, :include => :sender
    base.has_many :friend_acceptances, :class_name => "Friend::Acceptance", :dependent => :destroy, :include => :target
    base.has_many :friend_rejections, :class_name => "Friend::Rejection", :dependent => :destroy, :include => :target
  end

  # 相手と双方向のフレンドか調べる
  # * target - Userオブジェクトかidのどちらでもよい
  def friend?(target)
    target_id = target.kind_of?(User) ? target.id : target
    friend_acceptances.find_by_target_id(target_id) && friend_requests.find_by_sender_id(target_id)
  end

  # ユーザー側に、フレンド登録されたという情報を送る。
  # 別インスタンスに送る場合を考えて専用メソッドにしている。別インスタンスの場合はスタブのUserクラスの同名メソッドが通信を行う。
  def send_friend_request_from!(sender)
    raise "no sender" unless sender
    friend_requests.create!(:sender_id => sender.id)
  end
  # ユーザー側に、フレンド登録が解消されたという情報を送る。
  # 別インスタンスに送る場合を考えて専用メソッドにしている。別インスタンスの場合はスタブのUserクラスの同名メソッドが通信を行う。
  def cancel_friend_request_from!(sender)
    raise "no sender" unless sender
    r = friend_requests.find_by_sender_id(sender.id)
    r.destroy if r
  end
  # 現時点で双方向に登録されているフレンドユーザーを返す
  def friends
    friend_acceptances.requested.map{|a|a.target}
  end

end
