class GroupDebtSimplifier
  def self.calculate(group)
    balances = Hash.new(0)

    # Add expenses where users owe money
    ExpenseParticipant.joins(:expense).where(expenses: { group_id: group.id }).each do |ep|
      expense = ep.expense
      
      # If a user is part of the expense, their balance decreases by what they owe
      balances[ep.user_id] -= ep.amount_owed
      
      # The payer's balance increases by what others owe
      # Since amount_paid is handled for the payer, we could also just sum amount_paid - amount_owed for everyone.
      # Wait, expense_participants has amount_paid. Let's just use that.
      balances[ep.user_id] += ep.amount_paid
    end

    # Add settlements made within the group
    Settlement.where(group_id: group.id, status: 'completed').each do |s|
      balances[s.payer_id] += s.amount
      balances[s.receiver_id] -= s.amount
    end

    # Separate into debtors and creditors
    debtors = balances.select { |_, balance| balance < -0.01 }.map { |id, b| { user_id: id, amount: -b } }.sort_by { |d| -d[:amount] }
    creditors = balances.select { |_, balance| balance > 0.01 }.map { |id, b| { user_id: id, amount: b } }.sort_by { |c| -c[:amount] }

    simplified_debts = []

    # Greedily match debtors with creditors
    i = 0
    j = 0

    while i < debtors.length && j < creditors.length
      debtor = debtors[i]
      creditor = creditors[j]

      amount_to_settle = [debtor[:amount], creditor[:amount]].min

      simplified_debts << {
        payer_id: debtor[:user_id],
        receiver_id: creditor[:user_id],
        amount: amount_to_settle.round(2)
      }

      debtor[:amount] -= amount_to_settle
      creditor[:amount] -= amount_to_settle

      i += 1 if debtor[:amount] < 0.01
      j += 1 if creditor[:amount] < 0.01
    end

    users = User.where(id: simplified_debts.flat_map { |d| [d[:payer_id], d[:receiver_id]] }).index_by(&:id)

    simplified_debts.map do |debt|
      {
        payer: { id: debt[:payer_id], name: users[debt[:payer_id]]&.name },
        receiver: { id: debt[:receiver_id], name: users[debt[:receiver_id]]&.name },
        amount: debt[:amount]
      }
    end
  end
end
