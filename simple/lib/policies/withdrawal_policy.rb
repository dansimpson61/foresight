# WithdrawalPolicy: pure helper to withdraw funds to cover a shortfall
# Contract: withdraw_for_spending(amount_needed, accounts) -> array of events
# Respects either a provided order (symbols/strings) or the default: Taxable -> Traditional -> Roth
class WithdrawalPolicy
  class << self
    def withdraw_for_spending(amount_needed, accounts, order: nil)
      events = []
      remaining_need = amount_needed
      type_map = {
        'taxable' => TaxableAccount,
        :taxable => TaxableAccount,
        'traditional' => TraditionalIRA,
        :traditional => TraditionalIRA,
        'roth' => RothIRA,
        :roth => RothIRA
      }
      if order && order.respond_to?(:each)
        mapped = order.map { |t| type_map[t] }.compact
        withdrawal_order = mapped.empty? ? [TaxableAccount, TraditionalIRA, RothIRA] : mapped
      else
        withdrawal_order = [TaxableAccount, TraditionalIRA, RothIRA]
      end

      withdrawal_order.each do |account_class|
        break if remaining_need <= 0
        accounts.select { |a| a.is_a?(account_class) }.each do |account|
          break if remaining_need <= 0
          next unless account.balance > 0

          pulled = account.withdraw(remaining_need)
          remaining_need -= pulled
          taxes = account.tax_on_withdrawal(pulled)

          events << {
            type: :withdrawal,
            amount: pulled,
            taxable_ordinary: taxes[:ordinary_income],
            taxable_capital_gains: taxes[:capital_gains]
          } if pulled > 0
        end
      end

      events
    end
  end
end
