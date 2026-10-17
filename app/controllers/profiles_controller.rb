class ProfilesController < ApplicationController
  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(profile_params)
      redirect_to root_path, notice: "Профиль сохранён."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Роль и email менять нельзя. Учебные данные есть только у студента.
  def profile_params
    permitted = [ :first_name, :last_name ]
    permitted += [ :direction, :degree_level, :course, :group_name ] if @user.student?

    params.expect(user: permitted)
  end
end
