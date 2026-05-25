class Api::V1::SettlementsController < ApplicationController
  def index
    settlements = Settlement.where(payer: @current_user).or(Settlement.where(receiver: @current_user)).order(created_at: :desc)
    render json: settlements.map { |s|
      {
        id: s.id,
        amount: s.amount,
        payer: { id: s.payer.id, name: s.payer.name },
        receiver: { id: s.receiver.id, name: s.receiver.name },
        date: s.created_at,
        status: s.status
      }
    }
  end

  def create
    receiver_id = params.dig(:settlement, :receiver_id).to_i
    amount_to_settle = params.dig(:settlement, :amount).to_f

    # Validate against BalanceCalculatorService
    balances = BalanceCalculatorService.calculate_for(@current_user)
    owed_record = balances[:you_owe].find { |debt| debt[:user][:id] == receiver_id }

    if owed_record.nil? || amount_to_settle > owed_record[:amount]
      return render json: { error: "You can only settle an amount less than or equal to what you owe ($#{owed_record ? owed_record[:amount] : 0})" }, status: :unprocessable_entity
    end

    settlement = Settlement.new(settlement_params)
    settlement.payer = @current_user
    settlement.status = 'completed'

    if settlement.save
      render json: { message: 'Settlement recorded', settlement: settlement }, status: :created
    else
      render json: { error: settlement.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def settlement_params
    params.require(:settlement).permit(:receiver_id, :amount)
  end
end
