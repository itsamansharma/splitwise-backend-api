class Api::V1::ExpensesController < ApplicationController
  def index
    expenses = @current_user.participated_expenses.includes(:paid_by, :group).order(date: :desc)
    render json: expenses.map { |e| 
      {
        id: e.id,
        title: e.title,
        amount: e.amount,
        paid_by: { id: e.paid_by.id, name: e.paid_by.name },
        group: e.group ? { id: e.group.id, name: e.group.name } : nil,
        date: e.date,
        split_type: e.split_type
      }
    }
  end

  def create
    ActiveRecord::Base.transaction do
      expense = Expense.new(expense_params.merge(created_by: @current_user))
      
      if expense.save
        participants = params[:participants] || []
        
        participants.each do |p|
          amount_owed = p[:amount_owed].to_f
          is_payer = p[:user_id].to_i == expense.paid_by_id
          amount_paid = is_payer ? expense.amount : 0
          
          expense.expense_participants.create!(
            user_id: p[:user_id],
            amount_owed: amount_owed,
            amount_paid: amount_paid
          )
        end
        
        render json: { message: 'Expense created successfully', expense: expense }, status: :created
      else
        render json: { error: expense.errors.full_messages.join(', ') }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def expense_params
    params.require(:expense).permit(:title, :description, :amount, :paid_by_id, :group_id, :date, :split_type)
  end
end
