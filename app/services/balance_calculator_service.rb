class BalanceCalculatorService
  def self.calculate_for(user)
    balances = Hash.new(0)
    
    # 1. Calculate net balance for EVERY user in the system
    
    # Subtract what people owe for expenses
    ExpenseParticipant.find_each do |ep|
      balances[ep.user_id] -= ep.amount_owed
      balances[ep.user_id] += ep.amount_paid
    end

    # Add/subtract based on settlements
    Settlement.where(status: 'completed').find_each do |s|
      balances[s.payer_id] += s.amount
      balances[s.receiver_id] -= s.amount
    end

    # 2. Divide users into debtors and creditors
    debtors = balances.select { |_, balance| balance < -0.01 }.map { |id, b| { user_id: id, amount: -b } }.sort_by { |d| -d[:amount] }
    creditors = balances.select { |_, balance| balance > 0.01 }.map { |id, b| { user_id: id, amount: b } }.sort_by { |c| -c[:amount] }

    simplified_debts = []
    
    # 3. Greedily match debtors to creditors
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

    # 4. Filter for the requested user
    you_owe = simplified_debts.select { |d| d[:payer_id] == user.id }.map do |d|
      { user: { id: d[:receiver_id] }, amount: d[:amount].to_f }
    end
    
    you_are_owed = simplified_debts.select { |d| d[:receiver_id] == user.id }.map do |d|
      { user: { id: d[:payer_id] }, amount: d[:amount].to_f }
    end
    
    # Fetch user details
    user_ids = (you_owe.map { |d| d[:user][:id] } + you_are_owed.map { |d| d[:user][:id] }).uniq
    users_cache = User.where(id: user_ids).index_by(&:id)
    
    you_owe.each { |d| d[:user][:name] = users_cache[d[:user][:id]]&.name }
    you_are_owed.each { |d| d[:user][:name] = users_cache[d[:user][:id]]&.name }

    total_you_owe = you_owe.sum { |d| d[:amount] }
    total_you_are_owed = you_are_owed.sum { |d| d[:amount] }

    # 5. Return optimized dashboard data
    {
      total_you_owe: total_you_owe.to_f,
      total_you_are_owed: total_you_are_owed.to_f,
      you_owe: you_owe,
      you_are_owed: you_are_owed
    }
  end
end
