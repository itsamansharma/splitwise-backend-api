class Api::V1::DashboardController < ApplicationController
  def index
    balances = BalanceCalculatorService.calculate_for(@current_user)
    
    recent_expenses = @current_user.participated_expenses.order(date: :desc).limit(5).map do |e|
      { description: "#{e.paid_by.name} paid #{e.amount} for #{e.title}" }
    end

    render json: {
      total_you_owe: balances[:total_you_owe],
      total_you_are_owed: balances[:total_you_are_owed],
      you_owe: balances[:you_owe],
      you_are_owed: balances[:you_are_owed],
      recent_expenses: recent_expenses,
      groups: @current_user.groups.limit(5).map { |g| { id: g.id, name: g.name } }
    }
  end
end
