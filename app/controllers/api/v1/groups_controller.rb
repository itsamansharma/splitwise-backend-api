class Api::V1::GroupsController < ApplicationController
  def index
    groups = @current_user.groups.includes(:members)
    render json: groups.map { |g| 
      {
        id: g.id,
        name: g.name,
        description: g.description,
        members_count: g.members.count,
        members: g.members.map { |m| { id: m.id, name: m.name, email: m.email } }
      }
    }
  end

  def create
    group = Group.new(group_params.merge(created_by: @current_user))
    
    if group.save
      # Add creator as admin
      group.group_members.create!(user: @current_user, role: 'admin')
      
      # Add other members if provided
      member_ids = params[:member_ids] || []
      member_ids.each do |user_id|
        next if user_id == @current_user.id
        group.group_members.create(user_id: user_id, role: 'member')
      end

      render json: group, status: :created
    else
      render json: { error: group.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def show
    group = @current_user.groups.find_by(id: params[:id])
    if group
      render json: {
        id: group.id,
        name: group.name,
        description: group.description,
        members: group.members.map { |m| { id: m.id, name: m.name, email: m.email } },
        expenses: group.expenses.order(date: :desc).map { |e| 
          {
            id: e.id,
            title: e.title,
            amount: e.amount,
            paid_by: { id: e.paid_by.id, name: e.paid_by.name },
            date: e.date
          }
        }
      }
    else
      render json: { error: 'Group not found' }, status: :not_found
    end
  end

  def update
    group = @current_user.groups.find_by(id: params[:id])
    return render json: { error: 'Group not found' }, status: :not_found unless group

    ActiveRecord::Base.transaction do
      if params.dig(:group, :name).present?
        group.update!(name: params[:group][:name])
      end

      new_member_ids = params[:new_member_ids] || []
      added_user_ids = []

      new_member_ids.each do |user_id|
        unless group.group_members.exists?(user_id: user_id)
          group.group_members.create!(user_id: user_id, role: 'member')
          added_user_ids << user_id.to_i
        end
      end

      if added_user_ids.any?
        equal_expenses = group.expenses.where(split_type: 'equal')
        
        equal_expenses.each do |expense|
          current_participants = expense.expense_participants.map(&:user_id)
          all_participants = (current_participants + added_user_ids).uniq
          
          new_split_amount = expense.amount / all_participants.length
          
          expense.expense_participants.each do |ep|
            ep.update!(amount_owed: new_split_amount)
          end
          
          added_user_ids.each do |uid|
            unless current_participants.include?(uid)
              expense.expense_participants.create!(
                user_id: uid,
                amount_owed: new_split_amount,
                amount_paid: 0
              )
            end
          end
        end
      end

      render json: { message: 'Group updated successfully', group: group }, status: :ok
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def group_params
    params.require(:group).permit(:name, :description)
  end
end
