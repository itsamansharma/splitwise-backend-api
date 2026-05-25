require_dependency 'json_web_token'

class ApplicationController < ActionController::API
  before_action :authenticate_request

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    begin
      @decoded = JsonWebToken.decode(header)
      @current_user = User.find(@decoded[:user_id])
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def not_found(exception)
    render json: { error: 'Not found', message: exception.message }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { error: 'Unprocessable entity', message: exception.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def bad_request(exception)
    render json: { error: 'Bad request', message: exception.message }, status: :bad_request
  end

  def render_error(message, status = :internal_server_error)
    render json: { error: message }, status: status
  end
end
