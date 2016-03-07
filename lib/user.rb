require 'mongoid'

class User
  include Mongoid::Document

  field :email, type: String
  field :username, type: String
  field :password, type: String
  field :password_salt, type: String
  field :wordcount_badge, type: Integer

  validates :email,
    presence: true,
    uniqueness: true

end
