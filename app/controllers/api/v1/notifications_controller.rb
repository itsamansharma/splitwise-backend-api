class Api::V1::NotificationsController < ApplicationController
  def index
    notifications = @current_user.notifications_received.where(read: false).order(created_at: :desc)
    render json: notifications.map { |n|
      {
        id: n.id,
        sender: { id: n.sender.id, name: n.sender.name },
        notification_type: n.notification_type,
        message: n.message,
        created_at: n.created_at
      }
    }
  end

  def create
    receiver = User.find_by(id: params[:receiver_id])
    return render json: { error: 'Receiver not found' }, status: :not_found unless receiver

    # Ensure no duplicate unread reminder exists from the same person for the same type (to prevent spam)
    existing = Notification.find_by(
      sender: @current_user,
      receiver: receiver,
      notification_type: params[:notification_type] || 'payment_reminder',
      read: false
    )

    if existing
      return render json: { message: 'Reminder already sent and pending.' }, status: :ok
    end

    notification = Notification.new(
      sender: @current_user,
      receiver: receiver,
      notification_type: params[:notification_type] || 'payment_reminder',
      message: params[:message] || "#{@current_user.name} sent you a reminder."
    )

    if notification.save
      render json: { message: 'Reminder sent successfully' }, status: :created
    else
      render json: { error: notification.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def mark_as_read
    notification = @current_user.notifications_received.find_by(id: params[:id])
    return render json: { error: 'Notification not found' }, status: :not_found unless notification

    if notification.update(read: true)
      render json: { message: 'Notification marked as read' }
    else
      render json: { error: 'Failed to update notification' }, status: :unprocessable_entity
    end
  end
end
