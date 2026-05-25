class BalanceCalculatorService
  def self.calculate_for(user)
    you_owe = Hash.new(0)
    you_are_owed = Hash.new(0)

    # 1. Calculate from Expenses
    # Case A: User owes someone for an expense someone else paid
    user.expense_participants.includes(expense: :paid_by).each do |participant|
      expense = participant.expense
      next if expense.paid_by_id == user.id

      amount = participant.amount_owed
      if amount > 0
        you_owe[expense.paid_by_id] += amount
      end
    end

    # Case B: User paid for an expense, others owe user
    user.expenses_paid.includes(:expense_participants).each do |expense|
      expense.expense_participants.each do |participant|
        next if participant.user_id == user.id

        amount = participant.amount_owed
        if amount > 0
          you_are_owed[participant.user_id] += amount
        end
      end
    end

    # 2. Apply Settlements
    user.settlements_paid.where(status: 'completed').each do |settlement|
      you_owe[settlement.receiver_id] -= settlement.amount
    end

    user.settlements_received.where(status: 'completed').each do |settlement|
      you_are_owed[settlement.payer_id] -= settlement.amount
    end

    # 3. Simplify net balances
    you_owe.keys.each do |other_user_id|
      if you_are_owed[other_user_id] > 0
        if you_are_owed[other_user_id] >= you_owe[other_user_id]
          you_are_owed[other_user_id] -= you_owe[other_user_id]
          you_owe[other_user_id] = 0
        else
          you_owe[other_user_id] -= you_are_owed[other_user_id]
          you_are_owed[other_user_id] = 0
        end
      end
    end

    total_you_owe = you_owe.values.select { |v| v > 0 }.sum
    total_you_are_owed = you_are_owed.values.select { |v| v > 0 }.sum

    users_cache = User.where(id: you_owe.keys | you_are_owed.keys).index_by(&:id)

    formatted_you_owe = you_owe.select { |_, v| v > 0 }.map do |user_id, amount|
      { user: { id: user_id, name: users_cache[user_id]&.name }, amount: amount.to_f }
    end

    formatted_you_are_owed = you_are_owed.select { |_, v| v > 0 }.map do |user_id, amount|
      { user: { id: user_id, name: users_cache[user_id]&.name }, amount: amount.to_f }
    end

    {
      total_you_owe: total_you_owe.to_f,
      total_you_are_owed: total_you_are_owed.to_f,
      you_owe: formatted_you_owe,
      you_are_owed: formatted_you_are_owed
    }
  end
end
