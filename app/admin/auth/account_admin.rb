Trestle.resource(:account, model: User, scope: Auth, singular: true) do
  instance do
    current_user
  end

  remove_action :new, :edit, :destroy

  form do |user|
    text_field :email

    row do
      col(sm: 6) { static_field :alias_code }
      col(sm: 6) { static_field :admin do
          user.admin ? "✅" : "❌"
        end
      }
    end

    row do
      col(sm: 6) { password_field :password }
      col(sm: 6) { password_field :password_confirmation }
    end
  end

  # Limit the parameters that are permitted to be updated by the user
  params do |params|
    params.require(:account).permit(:email, :alias_code, :admin, :password, :password_confirmation)
  end
end
