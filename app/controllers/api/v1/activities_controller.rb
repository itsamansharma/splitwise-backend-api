class Api::V1::ActivitiesController < ApplicationController
  def index
    expenses = @current_user.participated_expenses.includes(:paid_by).order(created_at: :desc).limit(20)
    settlements = Settlement.where(payer: @current_user).or(Settlement.where(receiver: @current_user)).includes(:payer, :receiver).order(created_at: :desc).limit(20)
    
    activities = []
    
    expenses.each do |e|
      activities << {
        id: "exp_#{e.id}",
        type: 'expense',
        description: "#{e.paid_by.id == @current_user.id ? 'You' : e.paid_by.name} added expense '#{e.title}'",
        amount: e.amount,
        date: e.created_at
      }
    end

    settlements.each do |s|
      activities << {
        id: "set_#{s.id}",
        type: 'settlement',
        description: "#{s.payer.id == @current_user.id ? 'You' : s.payer.name} paid #{s.receiver.id == @current_user.id ? 'You' : s.receiver.name}",
        amount: s.amount,
        date: s.created_at
      }
    end

    activities.sort_by! { |a| a[:date] }.reverse!
    
    render json: activities.first(20)
  end
end
