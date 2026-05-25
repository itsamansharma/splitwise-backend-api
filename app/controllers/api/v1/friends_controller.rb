class Api::V1::FriendsController < ApplicationController
  def index
    accepted_friends = @current_user.friendships.where(status: 'accepted').map(&:friend) + 
                       @current_user.inverse_friendships.where(status: 'accepted').map(&:user)
    
    pending_requests = @current_user.inverse_friendships.where(status: 'pending')

    render json: {
      friends: accepted_friends.uniq.map { |u| { id: u.id, name: u.name, email: u.email } },
      pending_requests: pending_requests.map { |f| { id: f.id, user: { id: f.user.id, name: f.user.name, email: f.user.email } } }
    }
  end

  def create
    friend_email = params[:email]
    friend_user = User.find_by(email: friend_email)

    created_shadow = false

    if friend_user.nil?
      default_name = friend_email.split('@').first
      friend_user = User.create!(
        name: default_name, 
        email: friend_email, 
        password: 'test@123', 
        password_confirmation: 'test@123'
      )
      created_shadow = true
    end

    if friend_user == @current_user
      return render json: { error: 'You cannot add yourself as a friend' }, status: :unprocessable_entity
    end

    # Check if a friendship already exists in either direction
    existing = Friendship.where(user: @current_user, friend: friend_user).or(Friendship.where(user: friend_user, friend: @current_user)).first
    if existing
      return render json: { error: 'Friendship already exists or pending' }, status: :unprocessable_entity
    end

    friendship = @current_user.friendships.build(friend: friend_user, status: 'pending')
    
    if friendship.save
      render json: { 
        message: 'Friend request sent', 
        user: { id: friend_user.id, name: friend_user.name, email: friend_user.email },
        created_shadow_user: created_shadow
      }, status: :created
    else
      render json: { error: friendship.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def accept
    friendship = @current_user.inverse_friendships.find_by(id: params[:id], status: 'pending')
    if friendship&.update(status: 'accepted')
      render json: { message: 'Friend request accepted' }, status: :ok
    else
      render json: { error: 'Friend request not found or already processed' }, status: :not_found
    end
  end

  def destroy
    friendship = Friendship.find_by(id: params[:id])
    if friendship && (friendship.user == @current_user || friendship.friend == @current_user)
      friendship.destroy
      render json: { message: 'Friend removed' }, status: :ok
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end
end
